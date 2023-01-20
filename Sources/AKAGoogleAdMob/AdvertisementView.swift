import GoogleMobileAds
import SwiftUI
import UIKit
import Combine

public protocol AdvertisementTimeable {
    var showAfter: Date { get set }
    var intervalSeconds: Int { get set }
}

@available(iOS 13.0, *)
public struct AdvertisementView: UIViewControllerRepresentable {
    public let id: String
    public let advertisementTimeable: AdvertisementTimeable?
    public let automaticallyShowAd: (() -> Void)?
    public let tapDismiss: () -> Void
    public init(
        for id: String,
        advertisementTimeable: AdvertisementTimeable? = nil,
        automaticallyShowAd: (() -> Void)? = nil,
        tapDismiss: @escaping () -> Void
    ) {
        self.id = id
        self.advertisementTimeable = advertisementTimeable
        self.automaticallyShowAd = automaticallyShowAd
        self.tapDismiss = tapDismiss
    }

    public func makeUIViewController(context: Context) -> AdvertisementViewController {
        let viewController = AdvertisementViewController(
            id,
            advertisementTimeable: advertisementTimeable
        )
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_: AdvertisementViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final public class Coordinator: NSObject, AdvertisementViewControllerDelegate {
        public func automaticallyShowAd() {
            advertisementView.automaticallyShowAd?()
        }
        
        // MARK: - AdvertisementViewControllerDelegate
        public func adDidDismissFullScreenContent() {
            advertisementView.tapDismiss()
        }

        private let advertisementView: AdvertisementView

        init(_ view: AdvertisementView) {
            advertisementView = view
        }
    }
}

public protocol AdvertisementViewControllerDelegate: AnyObject {
    func adDidDismissFullScreenContent()
    func automaticallyShowAd()
}

@available(iOS 13.0, *)
public class AdvertisementViewController: UIViewController {

    weak var delegate: AdvertisementViewControllerDelegate?

    private let id: String
    private let advertisementTimeable: AdvertisementTimeable?
    private var cancellables: Set<AnyCancellable>
    
    @available(iOS 13.0, *)
    init(
        _ id: String,
        advertisementTimeable: AdvertisementTimeable?
    ) {
        self.id = id
        self.advertisementTimeable = advertisementTimeable
        self.cancellables = .init()
        super.init(nibName: nil, bundle: nil)
        
        bind()
    }
    
    private func bind() {
        guard let timeable = advertisementTimeable else { return }
        loop
            .schedule(
                after: .init(timeable.showAfter),
                interval: .seconds(timeable.intervalSeconds)
            ) { [weak self] in
                self?.delegate?.automaticallyShowAd()
            }
            .store(in: &cancellables)
    }
    
    private let loop = RunLoop.main

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        if advertisementTimeable == nil {
            configureManager()
        }
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
