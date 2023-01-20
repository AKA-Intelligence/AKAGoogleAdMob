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
    public let advertisementTimeable: AdvertisementTimeable?
    public let dismiss: (Bool) -> Void
    public init(
        for id: String,
        advertisementTimeable: AdvertisementTimeable? = nil,
        dismiss: @escaping (Bool) -> Void
    ) {
        self.id = id
        self.advertisementTimeable = advertisementTimeable
        self.dismiss = dismiss
        
        //만약 지금 보여줘야한다면, 광고를 바로 보여준다.
        let now = Calendar.current.date(byAdding: .second, value: 0, to: Date())!
        print(advertisementTimeable?.showAfter)
        print(now)
        if let showAfter = advertisementTimeable?.showAfter {
            print(showAfter)
            print(now)
            if showAfter == now {
                dismiss(false)
            }
        }
//        if advertisementTimeable?.showAfter == now {
//            dismiss(false)
//        }
        
        //타이머 셋팅이 안 되어 있다면, 광고를 바로 보여준다.
        else if advertisementTimeable == nil {
            dismiss(false)
        }
        
        else {
            dismiss(true)
        }
    }

    public func makeUIViewController(context: Context) -> AdvertisementViewController {
        let viewController = AdvertisementViewController(
            id,
            advertisementTimeable
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
//            advertisementView.automaticallyShowAd?()
            advertisementView.dismiss(false)
        }
        
        // MARK: - AdvertisementViewControllerDelegate
        public func adDidDismissFullScreenContent() {
            advertisementView.dismiss(true)
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
        _ advertisementTimeable: AdvertisementTimeable?
    ) {
        self.id = id
        self.advertisementTimeable = advertisementTimeable
        self.cancellables = .init()
        super.init(nibName: nil, bundle: nil)
        
        bind()
    }
    
    private func bind() {
        guard
            let timeable = advertisementTimeable,
            let dateNow = advertisementTimeable?.showAfter
        else { return }
        loop
            .schedule(
                after: .init(dateNow),
                interval: .seconds(timeable.intervalSeconds)
            ) { [weak self] in
                self?.delegate?.automaticallyShowAd()
                self?.configureManager()
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
