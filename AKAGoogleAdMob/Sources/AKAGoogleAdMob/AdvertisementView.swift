//public struct AKAGoogleAdMob {
//    public private(set) var text = "Hello, World!"
//
//    public init() {
//    }
//}

import GoogleMobileAds
import SwiftUI
import UIKit

@available(iOS 13.0, *)
public struct AdvertisementView: UIViewControllerRepresentable {
    public let type: GoogleAdMobType
    public let tapDismiss: () -> Void


    func makeUIViewController(context: Context) -> AdvertisementViewController {
        let viewController = AdvertisementViewController(type)
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_: AdvertisementViewController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, AdvertisementViewControllerDelegate {
        func adDidDismissFullScreenContent() {
            advertisementView.tapDismiss()
        }

        private let advertisementView: AdvertisementView

        init(_ view: AdvertisementView) {
            advertisementView = view
        }
    }

    typealias UIViewControllerType = AdvertisementViewController
}

protocol AdvertisementViewControllerDelegate: AnyObject {
    func adDidDismissFullScreenContent()
}

class AdvertisementViewController: UIViewController {

    weak var delegate: AdvertisementViewControllerDelegate?

    private let type: GoogleAdMobType

    init(_ type: GoogleAdMobType) {
        self.type = type
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureManager()
    }

    private var interstitial: GADInterstitialAd?

    private func configureManager() {
        let manager = GoogleAdMobManager()
        manager.create(type) {[weak self] ad in
            guard let self = self else { return }
            self.interstitial = ad
            self.interstitial?.present(fromRootViewController: self)
            self.interstitial?.fullScreenContentDelegate = self
        }
    }
}

//MARK: - GADFullScreenContentDelegate
extension AdvertisementViewController: GADFullScreenContentDelegate {
    /// Tells the delegate that the ad failed to present full screen content.
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content.")
    }

    /// Tells the delegate that the ad will present full screen content.
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }

    /// Tells the delegate that the ad dismissed full screen content.
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        delegate?.adDidDismissFullScreenContent()
        interstitial = nil
    }
}
