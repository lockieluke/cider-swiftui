//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import StoreKit
import MusicKit
import SwiftyJSON

class AMAPI {
    
    var AM_TOKEN: String = ""
    var AM_USER_TOKEN: String = "null"
    
    private let amNetworkingClient: NetworkingProvider
    private let ciderNetworkingClient: NetworkingProvider
    
    private var STOREFRONT_ID: String?
    
    init() {
        self.amNetworkingClient = NetworkingProvider(baseURL: URL(string: "https://api.music.apple.com/v1")!)
        self.ciderNetworkingClient = NetworkingProvider(baseURL: URL(string: "https://api.cider.sh/v1")!, defaultHeaders: ["User-Agent": "Cider SwiftUI"])
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
        do {
            let json = try await ciderNetworkingClient.requestJSON("/")
            self.AM_TOKEN = json["token"].stringValue
        } catch {
            print(error.localizedDescription)
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
    
    func initialiseAMNetworking() {
        self.amNetworkingClient.setDefaultHTTPHeaders(headers: [
            "Authorization": "Bearer \(AM_TOKEN)",
            "Music-User-Token": AM_USER_TOKEN,
            "Origin": "https://beta.music.apple.com",
            "Referrer": "https://beta.music.apple.com"
        ])
    }
    
    func unauthorise() {
        self.AM_USER_TOKEN = "null"
    }
    
    func initStorefront() async {
        print("AM_TOKEN: \(AM_TOKEN) Music User Token: \(AM_USER_TOKEN)")
        guard let responseJson = try? await amNetworkingClient.requestJSON("/me/storefront") else { return }
        
        let data = responseJson["data"].array?[0]
        let countryCode = data?["id"].stringValue
        
        self.STOREFRONT_ID = countryCode
    }
    
    func fetchRecommendations() async throws -> AMRecommendations {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/me/recommendations")
        } catch {
            throw AMNetworkingError.unableToFetchRecommendations(error.localizedDescription)
        }
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
                        return AMMediaItem(
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
