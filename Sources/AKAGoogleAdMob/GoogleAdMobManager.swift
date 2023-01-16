//
//  File.swift
//  
//
//  Created by Yoonsuk Kim on 2023/01/13.
//

import GoogleMobileAds
import Foundation

final class GoogleAdMobManager {
    func create(with id: String, completion: @escaping (Result<GADInterstitialAd?, Error>) -> Void) {
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
}
