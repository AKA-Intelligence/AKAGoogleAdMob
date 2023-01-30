import GoogleMobileAds
import SwiftUI
import UIKit
import Combine

public protocol AdvertisementTimeable {
    var showAfterSeconds: Int { get set }
    var intervalSeconds: Int { get set }
}

extension AdvertisementTimeable {
    var showAfter: Date? {
        Calendar.current.date(
            byAdding: .second,
            value: showAfterSeconds,
            to: Date()
        )
    }
}

@available(iOS 13.0, *)
public struct AdvertisementView: UIViewControllerRepresentable {
    public let id: String
    public var showAdPublisher: AnyPublisher<Bool, Never>
    public let adVertisementIsClosed: (Bool) -> Void
    
    public init(id: String, showAdPublisher: AnyPublisher<Bool, Never>, adVertisementIsClosed: @escaping (Bool) -> Void) {
        self.id = id
        self.showAdPublisher = showAdPublisher
        self.adVertisementIsClosed = adVertisementIsClosed
    }
    
    public func makeUIViewController(context: Context) -> AdvertisementViewController {
        let viewController = AdvertisementViewController(
            id,
            showAdPublisher
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_: AdvertisementViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final public class Coordinator: NSObject, AdvertisementViewControllerDelegate {
        // MARK: - AdvertisementViewControllerDelegate
        public func adDidDismissFullScreenContent() {
            advertisementView.adVertisementIsClosed(true)
        }

        private let advertisementView: AdvertisementView

        init(_ view: AdvertisementView) {
            advertisementView = view
        }
    }
}

public protocol AdvertisementViewControllerDelegate: AnyObject {
    func adDidDismissFullScreenContent()
}

@available(iOS 13.0, *)
public class AdvertisementViewController: UIViewController {

    weak var delegate: AdvertisementViewControllerDelegate?

    private let id: String
    private var showAdPublisher: AnyPublisher<Bool, Never>
    private var cancellables: Set<AnyCancellable>
    
    @available(iOS 13.0, *)
    init(
        _ id: String,
        _ showAdPublisher: AnyPublisher<Bool, Never>
    ) {
        self.id = id
        self.showAdPublisher = showAdPublisher
        self.cancellables = .init()
        super.init(nibName: nil, bundle: nil)
        
//        bind()
        showAdPublisher.sink {[weak self] needToShow in
            guard let self = self else { return }
            if needToShow {
                self.configureManager()
            }
        }
        .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var interstitial: GADInterstitialAd?

    private func configureManager() {
        let manager = GoogleAdMobManager()
        manager.create(with: id) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ad):
                self.interstitial = ad
                self.interstitial?.present(fromRootViewController: self)
                self.interstitial?.fullScreenContentDelegate = self
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

//MARK: - GADFullScreenContentDelegate
@available(iOS 13.0, *)
extension AdvertisementViewController: GADFullScreenContentDelegate {
    /// Tells the delegate that the ad failed to present full screen content.
    public func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }

    /// Tells the delegate that the ad will present full screen content.
    public func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }

    /// Tells the delegate that the ad dismissed full screen content.
    public func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.adDidDismissFullScreenContent()
        interstitial = nil
    }
}
