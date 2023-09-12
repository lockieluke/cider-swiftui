//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaItem {
    let id: String
    let title: String
    let curatorName: String
    let artistName: String
    let description: MediaDescription
    let type: MediaType
    let playlistType: PlaylistType?
    let artwork: MediaArtwork
    var tracks: [MediaTrack] = []
    let editorialArtwork: EditorialArtwork?
    
    let contentRating: String?
    let copyright: String?
    let genreNames: [String]
    let isCompilation: Bool
    let isComplete: Bool
    let isMasteredForItunes: Bool
    let isSingle: Bool
    let playParams: PlayParams?
    let recordLabel: String?
    let releaseDate: String?
    let trackCount: Int?
    let upc: String?
    let url: String?
    let audioVariants: [String]?
    
    init(data: JSON) {
        let attributes = data["attributes"]
        
        self.id = data["id"].stringValue
        self.title = attributes["name"].stringValue
        self.curatorName = attributes["curatorName"].stringValue
        self.artistName = attributes["artistName"].stringValue
        self.description = MediaDescription(data: attributes["description"])
        self.playlistType = PlaylistType(rawValue: attributes["playlistType"].stringValue)
        self.artwork = MediaArtwork(data: attributes["artwork"])
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
        
        if let editorialArtworkData = attributes["editorialArtwork"].dictionary {
            self.editorialArtwork = EditorialArtwork(data: JSON(editorialArtworkData))
        } else {
            self.editorialArtwork = nil
        }
        
        self.contentRating = attributes["contentRating"].string
        self.copyright = attributes["copyright"].string
        self.genreNames = attributes["genreNames"].arrayValue.map { $0.stringValue }
        self.isCompilation = attributes["isCompilation"].boolValue
        self.isComplete = attributes["isComplete"].boolValue
        self.isMasteredForItunes = attributes["isMasteredForItunes"].boolValue
        self.isSingle = attributes["isSingle"].boolValue
        self.playParams = PlayParams(data: attributes["playParams"])
        self.recordLabel = attributes["recordLabel"].string
        self.releaseDate = attributes["releaseDate"].string
        self.trackCount = attributes["trackCount"].int
        self.upc = attributes["upc"].string
        self.url = attributes["url"].string
        self.audioVariants = attributes["audioVariants"].arrayValue.map { $0.stringValue }
    }
}
