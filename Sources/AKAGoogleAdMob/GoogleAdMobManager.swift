//
//  File.swift
//  
//
//  Created by Yoonsuk Kim on 2023/01/13.
//

import GoogleMobileAds
import Foundation

final class GoogleAdMobManager {
    func createInterstial(
        with id: String,
        completion: @escaping (Result<GADInterstitialAd?, Error>) -> Void
    ) {
        let request = GADRequest()
        
        GADInterstitialAd
            .load(withAdUnitID: id, request: request) { ad, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(ad))
            }
    }
    
    func createRewarded(
        with id: String,
        completion: @escaping (Result<GADRewardedAd?, Error>) -> Void
    ) {
        let request = GADRequest()
        GADRewardedAd
            .load(withAdUnitID: id, request: request) { ad, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                completion(.success(ad))
            }
    }
}
