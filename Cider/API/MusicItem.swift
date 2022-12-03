//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MusicItem {
    
    let id: String, title: String, curatorName: String, description: String?, artistName: String
    let type: MediaType
    let playlistType: PlaylistType?
    let artwork: MusicArtwork
    var tracks: [MediaTrack] = []
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.curatorName = attributes["curatorName"].stringValue
        self.artistName = attributes["artistName"].stringValue
        self.description = attributes["description"]["standard"].string
        self.playlistType = PlaylistType(rawValue: attributes["playlistType"].stringValue)
        self.artwork = MusicArtwork(data: attributes["artwork"])
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
    }
    
}
