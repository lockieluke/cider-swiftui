//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MusicItem {
    
    let id: String
    let title: String
    let curatorName: String
    let description: String
    let type: MediaType
    let artwork: MusicArtwork
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.curatorName = attributes["curatorName"].stringValue
        self.description = attributes["description"]["standard"].stringValue
        self.artwork = MusicArtwork(data: attributes["artwork"])
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
    }
    
}
