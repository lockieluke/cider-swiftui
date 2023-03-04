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
        self.amNetworkingClient = NetworkingProvider(baseURL: URL(string: "https://amp-api.music.apple.com/v1")!, defaultHeaders: [
            "User-Agent": "Music/1.3.3 (Macintosh; OS X 13.2) AppleWebKit/614.4.6.1.5 build/2 (dt:1)",
            "Referer": "https://beta.music.apple.com",
            "Origin": "https://beta.music.apple.com"
        ])
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
            "Referer": "https://beta.music.apple.com"
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
    
    func fetchRecommendations() async throws -> MediaRecommendationSections {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/me/recommendations")
        } catch {
            throw AMNetworkingError.unableToFetchRecommendations(error.localizedDescription)
        }
        
        return MediaRecommendationSections(datas: responseJson)
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
    
    func fetchSong(id: String) async throws -> MediaTrack {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/catalog/\(STOREFRONT_ID!)/songs/\(id)")
        } catch {
            self.logger.error("Unable failed to tracks: \(error)")
            throw AMNetworkingError.unableToFetchTracks(error.localizedDescription)
        }
        
        return MediaTrack(data: responseJson["data"].array?.first ?? [])
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
        var responseJson: JSON
        do {
            var urlComponents = URLComponents(string: "/")!
            var urlQueryItems: [URLQueryItem] = []
            urlComponents.path = "/catalog/\(STOREFRONT_ID!)/artists/\(id)"
            
            if !params.isEmpty {
                urlQueryItems.append(URLQueryItem(name: "views", value: params.map { param in param.rawValue }.joined(separator: ",")))
            }
            if !extendParams.isEmpty {
                urlQueryItems.append(URLQueryItem(name: "extend", value: extendParams.map { param in param.rawValue }.joined(separator: ",")))
            }
            urlComponents.queryItems = urlQueryItems
            
            guard let urlString = urlComponents.url?.absoluteString else {
                throw AMNetworkingError.unableToFetchTracks("Unable to compose URL")
            }
            responseJson = try await amNetworkingClient.requestJSON(urlString)
        } catch {
            self.logger.error("Failed to fetch artist: \(error)")
            throw AMNetworkingError.unableToFetchTracks(error.localizedDescription)
        }
        
        let data = responseJson["data"].array?.first ?? []
        return MediaArtist(data: data)
    }
    
    enum FetchSearchSuggestionsKinds: String {
        case terms, topResults
    }
    
    enum FetchSearchTypes: String {
        case activities, albums, appleCurators = "apple-curators", artists, curators, musicVideos = "music-videos", playlists, recordLabels = "record-labels", songs, stations
    }
    
    @MainActor
    func fetchSearchSuggestions(term: String, kinds: [FetchSearchSuggestionsKinds] = [.terms, .topResults], types: [FetchSearchTypes] = [.artists, .songs, .musicVideos]) async -> SearchSuggestions {
        var responseJson: JSON
        do {
            var urlComponents = URLComponents(string: "/")!
            var urlQueryItems: [URLQueryItem] = []
            urlComponents.path = "/catalog/\(STOREFRONT_ID!)/search/suggestions"
            
            if !kinds.isEmpty {
                urlQueryItems.append(URLQueryItem(name: "kinds", value: kinds.map { kind in kind.rawValue }.joined(separator: ",")))
            }
            if !types.isEmpty {
                urlQueryItems.append(URLQueryItem(name: "types", value: types.map { type in type.rawValue }.joined(separator: ",")))
            }
            urlQueryItems.append(URLQueryItem(name: "term", value: term))
            urlComponents.queryItems = urlQueryItems
            
            guard let urlString = urlComponents.url?.absoluteString else {
                throw AMNetworkingError.unableToFetchTracks("Unable to compose URL")
            }
            responseJson = try await amNetworkingClient.requestJSON(urlString)
        } catch {
            self.logger.error("Failed to fetch search suggestions: \(error)")
            return SearchSuggestions(data: [])
        }
        
        let data = responseJson["results"]
        return SearchSuggestions(data: data)
    }
    
    @MainActor
    func fetchSearchResults(term: String, types: [FetchSearchTypes]) async -> SearchResults {
        var responseJson: JSON
        do {
            var urlComponents = URLComponents(string: "/")!
            var urlQueryItems: [URLQueryItem] = []
            urlComponents.path = "/catalog/\(STOREFRONT_ID!)/search"
            
            if !types.isEmpty {
                urlQueryItems.append(URLQueryItem(name: "types", value: types.map { type in type.rawValue }.joined(separator: ",")))
            }
            urlQueryItems.append(URLQueryItem(name: "term", value: term.replacingOccurrences(of: "", with: "+")))
            urlComponents.queryItems = urlQueryItems
            
            guard let urlString = urlComponents.url?.absoluteString else {
                throw AMNetworkingError.unableToFetchTracks("Unable to compose URL")
            }
            responseJson = try await amNetworkingClient.requestJSON(urlString)
        } catch {
            self.logger.error("Failed to fetch search results: \(error)")
            return SearchResults(data: [])
        }
        
        let data = responseJson["results"]
        return SearchResults(data: data)
    }
    
    @MainActor
    func fetchRatings(item: MediaDynamic) async -> MediaRatings {
        var responseJson: JSON
        do {
            responseJson = try await amNetworkingClient.requestJSON("/me/ratings/\(item.type)/\(item.id)")
        } catch {
//            self.logger.error("Failed to fetch ratings for \(item.id): \(error)")
            // If the media isn't given a rating, it will return 404
            return .Neutral
        }
        
        return MediaRatings(rawValue: responseJson["data"].array?.first?["attributes"]["value"].int ?? 0)!
    }
    
    @MainActor @discardableResult
    func setRatings(item: MediaDynamic, ratings: MediaRatings) async -> MediaRatings {
        var responseJson: JSON
        do {
            if ratings == .Neutral {
                responseJson = try await amNetworkingClient.requestJSON("/me/ratings/\(item.type)/\(item.id)", method: .PUT)
            } else {
                responseJson = try await amNetworkingClient.requestJSON("/me/ratings/\(item.type)/\(item.id)", method: .PUT, body: ["type": "rating", "attributes": [ "value": ratings.rawValue ]], bodyContentType: "application/json")
            }
        } catch {
            self.logger.error("Failed to set ratings for \(item.id): \(error)")
            return .Disliked
        }
        
        return MediaRatings(rawValue: responseJson["data"].array?.first?["attributes"]["value"].int ?? 0)!
    }
    
}
