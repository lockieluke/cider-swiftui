//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import StoreKit
import MusicKit
import SwiftyJSON

class AMAPI {
    
    var AM_TOKEN: String?
    var AM_USER_TOKEN: String?
    
    private let amNetworkingClient: NetworkingProvider
    private let ciderNetworkingClient: NetworkingProvider
    private let logger: Logger
    
    private var STOREFRONT_ID: String?
    
    init() {
        self.logger = Logger(label: "Apple Music API")
        self.amNetworkingClient = NetworkingProvider(baseURL: URL(string: "https://api.music.apple.com/v1")!)
        self.ciderNetworkingClient = NetworkingProvider(baseURL: URL(string: "https://api.cider.sh/v1")!, defaultHeaders: [
            "User-Agent": "Cider;?client=swiftui&env=dev&platform=darwin",
            "Referer": "localhost"
        ])
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
    
    func fetchMKDeveloperToken() async -> String {
        var amToken: String!
        do {
            let json = try await ciderNetworkingClient.requestJSON("/")
            
            if let token = json["token"].string {
                amToken = token
            } else {
                self.logger.error("MusicKit Developer Token could not be fetched", displayCross: true)
            }
        } catch {
            self.logger.error(error.localizedDescription)
        }
        
        self.AM_TOKEN = amToken
        return amToken
    }
    
    func fetchMKUserToken(completion: @escaping (_ succeeded: Bool, _ userToken: String?, _ error: Error?) -> Void) {
        if let AM_TOKEN = self.AM_TOKEN {
            SKCloudServiceController().requestUserToken(forDeveloperToken: AM_TOKEN) { token, error in
                if error != nil {
                    self.logger.error("Error occurred when fetching AM User Token: \(error!.localizedDescription)")
                    completion(false, nil, error)
                    return
                }
                
                guard let token = token else {
                    self.logger.error("MK User Token is undefined")
                    completion(false, nil, nil)
                    return
                }
                self.AM_USER_TOKEN = token
                completion(true, token, nil)
            }
        } else {
            completion(false, nil, AMAuthError.invalidDeveloperToken)
        }
    }
    
    func initialiseAMNetworking() throws {
        guard let AM_USER_TOKEN = self.AM_USER_TOKEN else { throw AMAuthError.invalidUserToken }
        guard let AM_TOKEN = self.AM_TOKEN else { throw AMAuthError.invalidDeveloperToken }
        
        self.amNetworkingClient.setDefaultHTTPHeaders(headers: [
            "Authorization": "Bearer \(AM_TOKEN)",
            "Music-User-Token": AM_USER_TOKEN,
            "Origin": "https://beta.music.apple.com",
            "Referrer": "https://beta.music.apple.com"
        ])
    }
    
    func unauthorise() {
        self.AM_USER_TOKEN = ""
    }
    
    func initStorefront() async {
        guard let responseJson = try? await amNetworkingClient.requestJSON("/me/storefront") else { return }
        
        let data = responseJson["data"].array?[0]
        let countryCode = data?["id"].stringValue
        
        self.STOREFRONT_ID = countryCode
    }
    
    func fetchRecommendations() async throws -> MusicRecommendationSections {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/me/recommendations")
        } catch {
            throw AMNetworkingError.unableToFetchRecommendations(error.localizedDescription)
        }
        
        return MusicRecommendationSections(datas: responseJson)
    }
    
    func fetchTracks(id: String, type: MediaType) async throws -> [MediaTrack] {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/catalog/\(STOREFRONT_ID!)/\(type.rawValue)/\(id)")
        } catch {
            self.logger.error("Unable failed to tracks: \(error)")
            throw AMNetworkingError.unableToFetchTracks(error.localizedDescription)
        }
        
        let data = responseJson["data"].array?[0]
        let tracks = data?["relationships"]["tracks"]["data"].arrayValue.map{ MediaTrack(data: $0) }
        
        return tracks ?? []
    }
    
}
