//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import StoreKit
import MusicKit
import SwiftyJSON
import Alamofire

struct APIEndpoints {
    static let AMAPI = "https://amp-api.music.apple.com/v1"
    static let CIDER = "https://api.cider.sh/v1"
}

class AMAPI {
    
    var AM_TOKEN: String?
    var AM_USER_TOKEN: String?
    
    private static var amSession: Session!
    private let logger = Logger(label: "Apple Music API")
    
    private var STOREFRONT_ID: String?
    
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
    
    func fetchMKDeveloperToken() async throws -> String {
        let res = await AF.request(APIEndpoints.CIDER, headers: [
            "User-Agent": "Cider;?client=swiftui&env=dev&platform=darwin",
            "Referer": "localhost"
        ]).serializingData().response
        
        if let error = res.error {
            self.logger.error("MusicKit Developer Token could not be fetched: \(error)", displayCross: true)
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let token = json["token"].string {
            self.AM_TOKEN = token
            return token
        }
        
        throw NSError(domain: "Failed to fetch MK Developer Account", code: 1)
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
        
        let configuration = URLSessionConfiguration.default
        let headers = HTTPHeaders([
            "User-Agent": "Music/1.3.3 (Macintosh; OS X 13.2) AppleWebKit/614.4.6.1.5 build/2 (dt:1)",
            "Authorization": "Bearer \(AM_TOKEN)",
            "Music-User-Token": AM_USER_TOKEN,
            "Origin": "https://beta.music.apple.com",
            "Referer": "https://beta.music.apple.com"
        ].merging(HTTPHeaders.default.dictionary, uniquingKeysWith: { (current, _) in current }))
        configuration.headers = headers
        
        AMAPI.amSession = Session(configuration: configuration)
    }
    
    func unauthorise() {
        self.AM_USER_TOKEN = ""
    }
    
    func initStorefront() async {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/storefront").serializingData().response
        
        if let error = res.error {
            self.logger.error("Failed to fetch storefront: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            self.STOREFRONT_ID = json["data"].array?.first?["id"].stringValue
        }
    }
    
    func fetchRecommendations() async throws -> MediaRecommendationSections {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/recommendations").serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch recommendations: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            return MediaRecommendationSections(datas: json)
        }
        
        return MediaRecommendationSections(datas: [])
    }
    
    func fetchTracks(id: String, type: MediaType) async throws -> [MediaTrack] {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/\(type.rawValue)/\(id)").serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch tracks: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let tracks = json["data"].array?.first?["relationships"]["tracks"]["data"].arrayValue.map({ MediaTrack(data: $0) }) {
            return tracks
        }
        
        return []
    }
    
    func fetchSong(id: String) async throws -> MediaTrack {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/songs/\(id)").serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch song: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let trackData = json["data"].array?.first {
            return MediaTrack(data: trackData)
        }
        
        return MediaTrack(data: [])
    }
    
    enum FetchArtistParams: String {
        case AppearsOnAlbum = "appears-on-albums",
             CompilationAlbums = "compilation-albums",
             FeaturedAlbums = "featured-albums",
             FeaturedMusicVideos = "featured-music-videos",
             FeaturedPlaylists = "featured-playlists",
             FullAlbums = "full-albums",
             LatestRelease = "latest-release",
             LiveAlbums = "live-albums",
             SimilarAritsts = "similar-artists",
             TopMusicVideos = "top-music-videos",
             TopSongs = "top-songs",
             Singles = "singles"
    }
    
    enum FetchArtistExtendParams: String {
        case artistBio, bornOrFormed, editorialArtwork, editorialVideo, isGroup, origin, hero
    }
    
    func fetchArtist(id: String, params: [FetchArtistParams] = [], extendParams: [FetchArtistExtendParams] = []) async throws -> MediaArtist {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/artists/\(id)", parameters: [
            "views": params.map { param in param.rawValue }.joined(separator: ","),
            "extend": extendParams.map { param in param.rawValue }.joined(separator: ",")
        ], encoding: URLEncoding(destination: .queryString)).serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch artist: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let artistData = json["data"].array?.first {
            return MediaArtist(data: artistData)
        }
        
        return MediaArtist(data: [])
    }
    
    enum FetchSearchSuggestionsKinds: String {
        case terms, topResults
    }
    
    enum FetchSearchTypes: String {
        case activities, albums, appleCurators = "apple-curators", artists, curators, musicVideos = "music-videos", playlists, recordLabels = "record-labels", songs, stations
    }
    
    @MainActor
    func fetchSearchSuggestions(term: String, kinds: [FetchSearchSuggestionsKinds] = [.terms, .topResults], types: [FetchSearchTypes] = [.artists, .songs, .musicVideos]) async throws -> SearchSuggestions {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/search/suggestions", parameters: [
            "kinds": kinds.map { kind in kind.rawValue }.joined(separator: ","),
            "types": types.map { type in type.rawValue }.joined(separator: ","),
            "term": term
        ], encoding: URLEncoding(destination: .queryString)).serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch search suggestions: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data) {
            return SearchSuggestions(data: json["results"])
        }
        
        return SearchSuggestions(data: [])
    }
    
    @MainActor
    func fetchSearchResults(term: String, types: [FetchSearchTypes]) async -> SearchResults {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/search", parameters: [
            "types": types.map { type in type.rawValue }.joined(separator: ","),
            "term": term.replacingOccurrences(of: "", with: "+")
        ], encoding: URLEncoding(destination: .queryString)).serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch search results: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            return SearchResults(data: json["results"])
        }
        
        return SearchResults(data: [])
    }
    
    @MainActor
    func fetchRatings(item: MediaDynamic) async -> MediaRatings {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/ratings/\(item.type)/\(item.id)").serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch ratings: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let rawRatings = json["data"].array?.first?["attributes"]["value"].int {
            return MediaRatings(rawValue: rawRatings)!
        }
        
        return .Neutral
    }
    
    @MainActor @discardableResult
    func setRatings(item: MediaDynamic, ratings: MediaRatings) async -> MediaRatings {
        let res = await (ratings == .Neutral ? AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/ratings/\(item.type)/\(item.id)", method: .delete) : AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/ratings/\(item.type)/\(item.id)", method: .put, parameters: ["type": "rating", "attributes": [ "value": ratings.rawValue ]], encoding: JSONEncoding.default)).serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch ratings: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let rawRatings = json["data"].array?.first?["attributes"]["value"].int {
            return MediaRatings(rawValue: rawRatings)!
        }
        
        return .Neutral
    }
    
    func fetchLibraryCatalog(item: MediaDynamic) async -> (Bool, String)? {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/", parameters: [
            "ids[\(item.type)]": (item.id as NSString).integerValue,
            "relate": "library",
            "fields": "inLibrary"
        ], encoding: URLEncoding(destination: .queryString)).serializingData().response
        if let error = res.error {
            self.logger.error("Failed to check if \(item.id) is in library: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let data = json["data"].array?.first, let inLibrary = data["attributes"]["inLibrary"].bool, let libraryId = data["relationships"]["library"]["data"].array?.first?["id"].string {
            return (inLibrary, libraryId)
        }
        
        return nil
    }
    
    @MainActor
    func isInLibrary(item: MediaDynamic) async -> Bool {
        let libraryCatalog = await self.fetchLibraryCatalog(item: item)
        return libraryCatalog?.0 ?? false
    }
    
    @MainActor
    func addToLibray(item: MediaDynamic, libraryId: String, _ add: Bool = true) async {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/library\(add ? "" : "/\(item.type)/\(libraryId)")", method: add ? .post : .delete, parameters: add ? [
            "ids[\(item.type)]": (item.id as NSString).integerValue
        ] : [:], encoding: add ? URLEncoding(destination: .queryString) : .default).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to add \(item.id) to library: \(error)")
        }
    }
    
    @MainActor
    func fetchLyricsXml(item: MediaDynamic) async -> String? {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/gb/\(item.type)/\(item.id)/lyrics").serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch lyrics \(item.id): \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let ttml = json["data"].array?.first?["attributes"]["ttml"].string {
            return ttml
        }
        
        return nil
    }
    
}
