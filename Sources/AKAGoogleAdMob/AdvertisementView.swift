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

public enum AdvertisementType {
    case interstitial, reward
}

public enum AdvertisementViewState {
    case rewarded, closed
}

public struct AdvertisementView: UIViewControllerRepresentable {
    public let type: AdvertisementType
    public let id: String
    public var showAdPublisher: AnyPublisher<Bool, Never>
    @Binding public var state: AdvertisementViewState?
    
    public init(
        type: AdvertisementType,
        id: String,
        showAdPublisher: AnyPublisher<Bool, Never>,
        state: Binding<AdvertisementViewState?> = .constant(nil)
    ) {
        self.type = type
        self.id = id
        self.showAdPublisher = showAdPublisher
        _state = state
    }
    
    public func makeUIViewController(context: Context) -> AdvertisementViewController {
        let viewController = AdvertisementViewController(
            type,
            id,
            showAdPublisher
        )
        viewController.rewardedDelegate = context.coordinator
        viewController.delegate = context.coordinator
        return viewController
    }

    public func updateUIViewController(_: AdvertisementViewController, context _: Context) {}

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final public class Coordinator: NSObject,
                                    AdvertisementViewControllerDelegate,
                                    RewardedAdViewControllerDelegate {
        
        public func userDidEarnReward() {
            advertisementView.state = .rewarded
        }
        
        public func adDidDismissFullScreenContent() {
            advertisementView.state = .closed
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

public protocol RewardedAdViewControllerDelegate: AnyObject {
    func userDidEarnReward()
}

public class AdvertisementViewController: UIViewController {

    weak var delegate: AdvertisementViewControllerDelegate?
    weak var rewardedDelegate: RewardedAdViewControllerDelegate?

    private let type: AdvertisementType
    private let id: String
    private var showAdPublisher: AnyPublisher<Bool, Never>
    private var cancellables: Set<AnyCancellable>
    
    init(
        _ type: AdvertisementType,
        _ id: String,
        _ showAdPublisher: AnyPublisher<Bool, Never>
    ) {
        self.type = type
        self.id = id
        self.showAdPublisher = showAdPublisher
        self.cancellables = .init()
        super.init(nibName: nil, bundle: nil)
        
        showAdPublisher
            .sink {[weak self] needToShow in
                guard let self = self else { return }
                if needToShow {
                    switch type {
                    case .reward:
                        self.configureRewarded()
                    case .interstitial:
                        self.configureInterstitial()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var interstitial: GADInterstitialAd?
    private var rewarded: GADRewardedAd?

    private func configureInterstitial() {
        let manager = GoogleAdMobManager()
        manager.createInterstial(with: id) {[weak self] result in
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
    
    private func configureRewarded() {
        let manager = GoogleAdMobManager()
        manager.createRewarded(with: id) {[weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let ad):
                self.rewarded = ad
                self.rewarded?.present(
                    fromRootViewController: self,
                    userDidEarnRewardHandler: {[weak self] in
                        guard let self = self else { return }
                        self.rewardedDelegate?.userDidEarnReward()
                })
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

//MARK: - GADFullScreenContentDelegate
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
