//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import StoreKit
import MusicKit
import Alamofire
import SwiftyJSON

class AMAPI {
    
    private let skCloudServiceController: SKCloudServiceController
    
    private var AM_TOKEN: String {
        get {
            return Bundle.main.object(forInfoDictionaryKey: "AM_API_TOKEN") as! String
        }
    }
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
                "Music-User-Token": AM_USER_TOKEN
            ]
        }
    }
    
    private var STOREFRONT_ID: String?
    
    init() {
        self.skCloudServiceController = SKCloudServiceController()
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
    
    func fetchMKUserToken(completion: @escaping (_ succeeded: Bool, _ userToken: String?, _ error: Error?) -> Void) {
        self.skCloudServiceController.requestUserToken(forDeveloperToken: AM_TOKEN) { token, error in
            if let error = error {
                print("Error occurred when fetching AM User Token: \(error.localizedDescription)")
                completion(false, nil, error)
                return
            }
            
            guard let token = token else {
                completion(false, nil, nil)
                return
            }
            self.AM_USER_TOKEN = token
            completion(true, token, nil)
        }
    }
    
    func checkAMSubscription(completion: @escaping (_ hasSubscription: Bool) -> Void) {
        self.skCloudServiceController.requestCapabilities { capabilities, error in
            if let error = error {
                print("Error occurred when fetching account capabilities: \(error.localizedDescription)")
                completion(false)
            }
            
            completion(capabilities.contains(.musicCatalogPlayback))
        }
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
