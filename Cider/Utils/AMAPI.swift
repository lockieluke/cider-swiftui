//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import StoreKit
import MusicKit
import Alamofire
import SwiftyJSON

class AMAPI {
    
    private var AM_TOKEN: String
    private var AM_USER_TOKEN: String = "null"
    public var SAFE_AM_TOKEN: String {
        get {
            // might do checks to prevent token leak
            return self.AM_TOKEN
        }
    }
    private let AM_API_END = "https://api.music.apple.com/v1"
    private var AM_HEADERS: HTTPHeaders {
        get {
            return [
                "Authorization": "Bearer \(AM_TOKEN)",
                "Music-User-Token": AM_USER_TOKEN,
                "Origin": "https://beta.music.apple.com",
                "Referrer": "https://beta.music.apple.com"
            ]
        }
    }
    
    private var STOREFRONT_ID: String?
    
    init() {
        self.AM_TOKEN = ""
    }
    
    func requestSKAuthorisation(completion: @escaping (_ status: SKCloudServiceAuthorizationStatus) -> Void) {
        SKCloudServiceController.requestAuthorization { status in
            completion(status)
        }
    }
    
    func requestMKAuthorisation(completion: @escaping (_ mkStatus: MusicAuthorization.Status) -> Void) {
        Task {
            let status = await MusicAuthorization.request()
            
            completion(status)
        }
    }
    
    func fetchMKDeveloperToken() async {
        let response = await AF.request("https://api.cider.sh/v1", headers: [
            "User-Agent": "Cider SwiftUI"
        ]).validate().serializingData().response
        
        if let data = response.data {
            let json = try? JSON(data: data)
            if let token = json?["token"].stringValue {
                self.AM_TOKEN = token
            }
        }
    }
    
    func fetchMKUserToken(completion: @escaping (_ succeeded: Bool, _ userToken: String?, _ error: Error?) -> Void) {
        SKCloudServiceController().requestUserToken(forDeveloperToken: AM_TOKEN) { token, error in
            if error != nil {
                print("Error occurred when fetching AM User Token: \(error!.localizedDescription)")
                completion(false, nil, error)
                return
            }
            
            guard let token = token else {
                print("MK User Token is undefined")
                completion(false, nil, nil)
                return
            }
            self.AM_USER_TOKEN = token
            completion(true, token, nil)
        }
    }
    
    func setUserToken(userToken: String) {
        self.AM_USER_TOKEN = userToken
    }
    
    func fetchAPI(_ endpoint: String) async throws -> JSON {
        let afReq = AF.request("\(AM_API_END)\(endpoint)", method: .get, headers: AM_HEADERS).serializingData()
        let response = await afReq.response
        guard let data = response.data else { throw NSError(domain: "Error fetching \(endpoint)", code: .zero)}
        let json = try? JSON(data: data)
        
        return json ?? JSON()
    }
    
    func initStorefront() async {
        print("AM_TOKEN: \(AM_TOKEN) Music User Token: \(AM_USER_TOKEN)")
        let responseJson = try! await self.fetchAPI("/me/storefront")
        let data = responseJson["data"].array?[0]
        let countryCode = data?["id"].stringValue
        
        self.STOREFRONT_ID = countryCode
    }
    
    func fetchRecommendation() async -> AMRecommendations {
        let responseJson = try! await self.fetchAPI("/me/recommendations")
        let recommendationCategories = responseJson["data"].array ?? []
        
        return AMRecommendations(
            id: responseJson["id"].stringValue,
            contents: recommendationCategories.map({json in
                return AMRecommendationSection(
                    title: json["attributes"]["title"]["stringForDisplay"].stringValue,
                    id: json["id"].stringValue,
                    recommendations: json["relationships"]["contents"]["data"].arrayValue.map { data in
                        let attributes = data["attributes"]
                        let artwork = attributes["artwork"]
                        return AMRecommendation(
                            title: attributes["name"].stringValue,
                            artwork: AMArtwork(
                                url: artwork["url"].stringValue,
                                size: NSSize(width: artwork["width"].doubleValue, height: artwork["height"].doubleValue),
                                bgColour: NSColor(hex: artwork["bgColor"].stringValue)
                            )
                        )
                    }
                )
            })
        )
    }
    
    
}
