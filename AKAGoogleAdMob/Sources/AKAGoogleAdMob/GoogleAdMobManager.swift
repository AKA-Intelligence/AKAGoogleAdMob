//
//  File.swift
//  
//
//  Created by Yoonsuk Kim on 2023/01/13.
//

import Foundation

import GoogleMobileAds
import Foundation

public enum GoogleAdMobType: String {
    case test = "ca-app-pub-3940256099942544/4411468910"
    case aiTalkResultDetailPage = "ca-app-pub-6177936669931786/3255721988"
    case hawaiiDialogueComplete = "ca-app-pub-6177936669931786/7107337088"
    case hawaiiQuizComplete = "ca-app-pub-6177936669931786/9156831645"
}

final class GoogleAdMobManager {
    func create(_ type: GoogleAdMobType, completion: @escaping (GADInterstitialAd?) -> Void) {
        let request = GADRequest()

        GADInterstitialAd
            .load(withAdUnitID: type.rawValue, request: request) { ad, error in
                if let error = error {
                    print(error)
                    completion(nil)
                    return
                }
                completion(ad)
        }
    }
}
