//
//  MediaArtist.swift
//  Cider
//
//  Created by Sherlock LUK on 23/01/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaArtist {
    
    let id: String
    let url: String
    let genres: [String]
    let artistName: String
    let artwork: MusicArtwork
    let topSongs: [MediaTrack]
    let latestReleases: [MediaTrack]
    
    let artistBio: String?
    let origin: String?
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.artistName = attributes["name"].stringValue
        self.artwork = MusicArtwork(data: attributes["artwork"])
        self.url = attributes["url"].stringValue
        self.genres = attributes["genreNames"].arrayValue.map { $0.stringValue }
        
        self.artistBio = attributes["artistBio"].string
        self.origin = attributes["origin"].string
        
        let views = data["views"]
        self.topSongs = views["top-songs"]["data"].arrayValue.map { MediaTrack(data: $0) }
        self.latestReleases = views["latest-release"]["data"].arrayValue.map { MediaTrack(data: $0) }
    }
    
}
