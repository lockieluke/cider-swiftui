//
//  MediaPlaylist.swift
//  Cider
//
//  Created by Sherlock LUK on 14/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaPlaylist: Identifiable {
    
    let id: String
    let title: String
    let curatorName: String
    let playlistType: PlaylistType?
    let description: MediaDescription
    let artwork: MediaArtwork
    let playParams: PlayParams
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.curatorName = attributes["curatorName"].stringValue
        self.playlistType = PlaylistType(rawValue: attributes["playlistType"].stringValue)
        self.description = MediaDescription(data: attributes["description"])
        self.artwork = MediaArtwork(data: attributes["artwork"])
        self.playParams = PlayParams(data: attributes["playParams"])
    }
    
}
