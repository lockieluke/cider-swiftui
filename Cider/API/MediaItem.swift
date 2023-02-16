//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MediaItem {
    
    let id: String, title: String, curatorName: String, artistName: String
    let description: MediaDescription
    let type: MediaType
    let playlistType: PlaylistType?
    let artwork: MediaArtwork
    var tracks: [MediaTrack] = []
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.curatorName = attributes["curatorName"].stringValue
        self.artistName = attributes["artistName"].stringValue
        self.description = MediaDescription(data: attributes["description"])
        self.playlistType = PlaylistType(rawValue: attributes["playlistType"].stringValue)
        self.artwork = MediaArtwork(data: attributes["artwork"])
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
    }
    
}
