//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import StoreKit
import MusicKit
import SwiftyJSON
import Alamofire
import ZippyJSON

struct APIEndpoints {
    static let AMAPI = "https://amp-api.music.apple.com/v1"
    static let CIDER = "https://api.cider.sh/v1"
}

class AMAPI {
    
    var AM_TOKEN: String?
    var AM_USER_TOKEN: String?
    
    private static var amSession: Session!
    private let logger = Logger(label: "Apple Music API")
    private let cacheModal: CacheModal
    
    private var STOREFRONT_ID: String?
    private var noAuthHeaders: HTTPHeaders {
        get {
            var headers: HTTPHeaders = [
                "User-Agent": "Music/1.3.3 (Macintosh; OS X 13.2) AppleWebKit/614.4.6.1.5 build/2 (dt:1)",
                "Origin": "https://beta.music.apple.com",
                "Referer": "https://beta.music.apple.com"
            ]
            if let AM_TOKEN = self.AM_TOKEN {
                headers["Authorization"] = "Bearer \(AM_TOKEN)"
            }
            
            return headers
        }
    }
    
    init(cacheModal: CacheModal) {
        self.cacheModal = cacheModal
    }
    
    func requestMKAuthorisation() async -> MusicAuthorization.Status {
        return await MusicAuthorization.request()
    }
    
    func fetchMKDeveloperToken(ignoreCache: Bool = false) async throws -> String {
        // Spends less time on decoding when JSON is hardcoded
        struct CiderAPIResponse: Decodable {
            let token: String
            let time: Int
        }
        
        let timer = ParkBenchTimer()
        if !ignoreCache, let lastAmToken = try? self.cacheModal.storage?.object(forKey: "last_am_token") {
            self.logger.info("Fetching cached developer token took \(timer.stop())")
            self.AM_TOKEN = lastAmToken
            return lastAmToken
        }
        
        var request = URLRequest(url: URL(string: APIEndpoints.CIDER)!)
        request.headers = [
            "User-Agent": "Cider",
            "Referer": "localhost"
        ]
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let json = try ZippyJSONDecoder().decode(CiderAPIResponse.self, from: data)
        self.AM_TOKEN = json.token
        try self.cacheModal.storage?.setObject(json.token, forKey: "last_am_token", expiry: .date(Date().addingTimeInterval(60 * 60 * 24 * 30)))
        self.logger.info("Fetching developer token took \(timer.stop())")
        return json.token
    }
    
    func initialiseAMNetworking() throws {
        guard let AM_USER_TOKEN = self.AM_USER_TOKEN else { throw AMAuthError.invalidUserToken }
        
        let configuration = URLSessionConfiguration.default
        var headers = self.noAuthHeaders
        headers["Music-User-Token"] = AM_USER_TOKEN
        configuration.headers = headers
        
        AMAPI.amSession = Session(configuration: configuration)
    }
    
    func unauthorise() {
        self.AM_USER_TOKEN = ""
    }
    
    func initStorefront() async -> Bool {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/storefront").validate().serializingData().response
        
        if let error = res.error {
            self.logger.error("Failed to fetch storefront: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            self.STOREFRONT_ID = json["data"].array?.first?["id"].stringValue
            return true
        }
        
        return false
    }
    
    func validateUserToken(_ userToken: String) async -> Bool {
        if let AM_TOKEN = self.AM_TOKEN {
            let res = await AF.request("\(APIEndpoints.AMAPI)/me/account", parameters: [
                "meta": "subscription",
                "challenge[subscriptionCapabilities]": "voice,premium"
            ], headers: [
                "Music-User-Token": userToken,
                "Authorization": "Bearer \(AM_TOKEN)"
            ]).validate().serializingData().response
            
            if let error = res.error {
                self.logger.error("Failed to validate user token: \(error)")
            } else if res.response?.statusCode == 200, let data = res.data, let json = try? JSON(data: data) {
                return json["data"]["meta"]["subscription"].boolValue
            }
        }
        
        return false
    }
    
    func fetchRecommendations() async -> MediaRecommendationSections {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/recommendations").validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch recommendations: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            return MediaRecommendationSections(datas: json)
        }
        
        return MediaRecommendationSections(datas: [])
    }
    
    func fetchPersonalRecommendation() async -> [MediaPlaylist] {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/recommendations", parameters: [
            "timezone": DateUtils.formatTimezoneOffset(),
            "name": "listen-now",
            "with": "friendsMix,library,social",
            "art[social-profiles:url]": "c",
            "art[url]": "c,f",
            "omit[resource]": "autos",
            "relate[editorial-items]": "contents",
            "extend": "editorialCard,editorialVideo",
            "extend[albums]": "artistUrl",
            "extend[library-albums]": "artistUrl,editorialVideo",
            "extend[playlists]": "artistNames,editorialArtwork,editorialVideo",
            "extend[library-playlists]": "artistNames,editorialArtwork,editorialVideo",
            "extend[social-profiles]": "topGenreNames",
            "include[albums]": "artists",
            "include[songs]": "artists",
            "include[music-videos]": "artists",
            "fields[albums]": "artistName,artistUrl,artwork,contentRating,editorialArtwork,editorialVideo,name,playParams,releaseDate,url",
            "fields[artists]": "name,url",
            "extend[stations]": "airDate,supportsAirTimeUpdates",
            "meta[stations]": "inflectionPoints",
            "types": "artists,albums,editorial-items,library-albums,library-playlists,music-movies,music-videos,playlists,stations,uploaded-audios,uploaded-videos,activities,apple-curators,curators,tv-shows,social-upsells",
            "platform": "web"
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch personal recommendations: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let sections = json["data"].array {
            // https://github.com/ciderapp/project2/blob/main/src/components/applemusic/pageContent/AMHome.vue#L130
            let section = sections.first { section in
                return section["meta"]["metrics"]["moduleType"].intValue == 6
            }
            
            let items = section?["relationships"]["contents"]["data"].arrayValue.compactMap { item in
                return MediaPlaylist(data: item)
            }
            return items ?? []
        }
        
        return []
    }
    
    func fetchTracks(id: String, type: MediaType) async throws -> [MediaTrack] {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(self.STOREFRONT_ID!)/\(type.rawValue)/\(id)").validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch tracks: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let tracks = json["data"].array?.first?["relationships"]["tracks"]["data"].arrayValue.map({ MediaTrack(data: $0) }) {
            return tracks
        }
        
        return []
    }
    
    func fetchSong(id: String) async throws -> MediaTrack {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/songs/\(id)", parameters: [
            "art[url]": "f",
            "extend": "artistUrl,editorialArtwork,plainEditorialNotes",
            "fields[albums]": "artistName,artistUrl,artwork,contentRating,editorialArtwork,plainEditorialNotes,name,playParams,releaseDate,url,trackCount,genreNames,isComplete,isSingle,recordLabel,audioVariants,copyright,isCompilation,isMasteredForItunes,upc",
            "include[albums]": "artists,tracks,music-videos",
            "platform": "web",
        ]).validate().serializingData().response
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
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch artist: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let artistData = json["data"].array?.first {
            return MediaArtist(data: artistData)
        }
        
        return MediaArtist(data: [])
    }
    
    func fetchPlaylist(id: String) async throws -> MediaPlaylist {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/playlists/\(id)", encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch playlist: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let playlistData = json["data"].array?.first {
            return MediaPlaylist(data: playlistData)
        }
        
        return MediaPlaylist(data: [])
    }
    
    func fetchAlbum(id: String) async throws -> MediaItem {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/albums/\(id)", parameters: [
            "art[url]": "f",
            "extend": "artistUrl,editorialArtwork,editorialNotes",
            "fields[albums]": "artistName,artistUrl,artwork,attribution,composerName,discNumber,durationInMillis,contentRating,hasLyrics,isAppleDigitalMaster,isrc,movementCount,movementName,movementNumber,workName,editorialArtwork,editorialNotes,name,playParams,releaseDate,url,genreNames,audioVariants",
            "include[albums]": "artists,tracks,music-videos",
            "platform": "web",
        ],  encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch album: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let albumData = json["data"].array?.first {
            return MediaItem(data: albumData)
        }
        
        return MediaItem(data: [])
    }
    
    enum FetchSearchSuggestionsKinds: String {
        case terms, topResults
    }
    
    enum FetchSearchTypes: String {
        case activities, albums, appleCurators = "apple-curators", artists, curators, musicVideos = "music-videos", playlists, recordLabels = "record-labels", songs, stations
    }
    
    func fetchSearchSuggestions(term: String, kinds: [FetchSearchSuggestionsKinds] = [.terms, .topResults], types: [FetchSearchTypes] = [.artists, .songs, .musicVideos]) async throws -> SearchSuggestions {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/search/suggestions", parameters: [
            "kinds": kinds.map { kind in kind.rawValue }.joined(separator: ","),
            "types": types.map { type in type.rawValue }.joined(separator: ","),
            "term": term
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch search suggestions: \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data) {
            return SearchSuggestions(data: json["results"])
        }
        
        return SearchSuggestions(data: [])
    }
    
    func fetchSearchResults(term: String, types: [FetchSearchTypes]) async -> SearchResults {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(self.STOREFRONT_ID!)/search", parameters: [
            "types": types.map { type in type.rawValue }.joined(separator: ","),
            "term": term.replacingOccurrences(of: "", with: "+")
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch search results: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data) {
            return SearchResults(data: json["results"])
        }
        
        return SearchResults(data: [])
    }
    
    func fetchRating(item: MediaDynamic) async -> MediaRatings {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/ratings/\(item.type)", parameters: ["ids": "\(item.id)"])
            .validate()
            .serializingData()
            .response
        
        guard
            let data = res.data,
            let json = try? JSON(data: data),
            let rawRatings = json["data"].array?.first?["attributes"]["value"].int
        else {
            if let error = res.error {
                self.logger.error("Failed to fetch ratings: \(error)")
            }
            return .Neutral
        }
        
        return MediaRatings(rawValue: rawRatings)!
    }
    
    func setRating(item: MediaDynamic, rating: MediaRatings) async -> MediaRatings {
        let method: Alamofire.HTTPMethod = (rating == .Neutral) ? .delete : .put
        let parameters: [String: Any]? = (rating != .Neutral) ? ["attributes": ["value": rating.rawValue]] : nil
        
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/ratings/\(item.type)/\(item.id)", method: method, parameters: parameters, encoding: JSONEncoding.default)
            .validate()
            .serializingData()
            .response
        
        guard
            let data = res.data,
            let json = try? JSON(data: data),
            let rawRatings = json["data"].array?.first?["attributes"]["value"].int
        else {
            if let error = res.error {
                self.logger.error("Error occurred when setting rating to \(rating): \(error)")
            }
            return rating
        }
        
        return MediaRatings(rawValue: rawRatings)!
    }
    
    func fetchLibraryCatalog(item: MediaDynamic) async -> Bool? {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/", parameters: [
            "ids[\(item.type)]": (item.id as NSString).integerValue,
            "relate": "library",
            "fields": "inLibrary"
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to check if \(item.id) is in library: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let data = json["data"].array?.first { return data["attributes"]["inLibrary"].bool
            
        }
        
        return nil
    }
    
    func isInLibrary(item: MediaDynamic) async -> Bool {
        let libraryCatalog = await self.fetchLibraryCatalog(item: item)
        return libraryCatalog ?? false
    }
    
    func addToLibrary(item: MediaDynamic, _ add: Bool = true) async -> Bool {
        var query: String = "\(APIEndpoints.AMAPI)/me/library"
        var parameters: Parameters = [:]
        parameters["ids[\(item.type)]"] = item.id
        
        if !add {
            query = "\(APIEndpoints.AMAPI)/me/library/\(item.type.replacingOccurrences(of: "library-", with: ""))/\(item.id)"
            parameters["ids[\(item.type)]"] = item.id
            
            if !item.type.contains("library-") {
                do {
                    let libraryItem = try await fetchLibraryItem(item: item)
                    query = "\(APIEndpoints.AMAPI)/me/library/\(item.type.replacingOccurrences(of: "library-", with: ""))/\(libraryItem.id)"
                    parameters["ids[\(libraryItem.type)]"] = libraryItem.id
                } catch {
                    print("Error occurred while trying to fetch LibraryItem")
                }
            }
        }
        
        return await withCheckedContinuation { continuation in
            AMAPI.amSession.request(query, method: add ? .post : .delete, parameters: parameters, encoding: URLEncoding(destination: .queryString)).validate().response { response in
                switch response.result {
                case .success:
                    if let statusCode = response.response?.statusCode, (200..<300).contains(statusCode) {
                        continuation.resume(returning: true)
                    } else {
                        self.logger.error("Unexpected status code: \(String(describing: response.response?.statusCode)) when trying to \(add ? "add" : "remove") \(item.id) from library.")
                        continuation.resume(returning: false)
                    }
                case .failure(let error):
                    if let statusCode = response.response?.statusCode, (200..<300).contains(statusCode) {
                        continuation.resume(returning: true)
                    } else {
                        self.logger.error("Failed to \(add ? "add" : "remove") \(item.id) from library due to error: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }
    
    func fetchLibraryItem(item: MediaDynamic) async throws -> MediaDynamic {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/\(STOREFRONT_ID!)/\(item.type)/\(item.id)/library", parameters: [
            "art[url]": "f",
            "extend": "artistUrl,editorialArtwork,editorialNotes",
            "fields[albums]": "artistName,artistUrl,artwork,attribution,composerName,discNumber,durationInMillis,contentRating,hasLyrics,isAppleDigitalMaster,isrc,movementCount,movementName,movementNumber,workName,editorialArtwork,editorialNotes,name,playParams,releaseDate,url,genreNames,audioVariants",
            "include[albums]": "artists,tracks,music-videos",
            "platform": "web",
        ],  encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch library \(item.type): \(error)")
            throw error
        } else if let data = res.data, let json = try? JSON(data: data), let albumData = json["data"].array?.first {
            return .mediaItem(MediaItem(data: albumData))
        }
        return .mediaItem(MediaItem(data: []))
    }
    
    func fetchLyricsXml(item: MediaDynamic) async -> String? {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/catalog/gb/\(item.type)/\(item.id)/syllable-lyrics").validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch lyrics \(item.id): \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let ttml = json["data"].array?.first?["attributes"]["ttml"].string {
            return ttml
        }
        
        return nil
    }
    
    struct SocialProfile {
        let handle, name, url: String
        let isPrivate, isVerified: Bool
        
        init(attributes: JSON) {
            self.handle = attributes["handle"].stringValue
            self.isPrivate = attributes["isPrivate"].boolValue
            self.isVerified = attributes["isVerified"].boolValue
            self.name = attributes["name"].stringValue
            self.url = attributes["url"].stringValue
        }
    }
    
    func fetchPersonalSocialProfile() async -> SocialProfile? {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/social-profile").validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch personal social profile: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let attributes = json["data"].array?.first?["attributes"] {
            return SocialProfile(attributes: attributes)
        }
        
        return nil
    }
    
    func fetchRecentlyPlayed(limit: Int? = nil) async -> [MediaDynamic] {
        var parameters: [String : Any]? = nil
        if let limit = limit {
            parameters?["limit"] = limit
        }
        
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/me/recent/played", parameters: parameters, encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch personal social profile: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let items = json["data"].array {
            return items.compactMap { item in
                switch MediaType(rawValue: item["type"].stringValue) {
                    
                case .Song:
                    return .mediaTrack(MediaTrack(data: item))
                    
                case .Playlist:
                    return .mediaPlaylist(MediaPlaylist(data: item))
                    
                default:
                    return .mediaItem(MediaItem(data: item))
                }
            }
        }
        
        return []
    }
    
    func fetchBrowse() async -> [MediaBrowseData] {
        let res = await AMAPI.amSession.request("\(APIEndpoints.AMAPI)/editorial/\(self.STOREFRONT_ID!)/groupings", parameters: [
            "art[url]": "f",
            "extend": "artistUrl,editorialArtwork,plainEditorialNotes",
            "extend[station-events]": "editorialVideo",
            "fields[albums]":
                "artistName,artistUrl,artwork,contentRating,editorialArtwork,plainEditorialNotes,name,playParams,releaseDate,url,trackCount",
            "fields[artists]": "name,url,artwork",
            "include[albums]": "artists",
            "include[music-videos]": "artists",
            "include[songs]": "artists",
            "include[stations]": "events",
            "name": "music",
            "omit[resource:artists]": "relationships",
            "platform": "web",
            "relate[songs]": "albums",
            "tabs": "subscriber"
        ], encoding: URLEncoding(destination: .queryString)).validate().serializingData().response
        if let error = res.error {
            self.logger.error("Failed to fetch browse: \(error)")
        } else if let data = res.data, let json = try? JSON(data: data), let tabsChildren = json["data"].array?.first?["relationships"]["tabs"]["data"].array?.first?["relationships"]["children"]["data"].array {
            return tabsChildren.compactMap { MediaBrowseData(data: $0) }
        }
        
        return []
    }
}
