//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MediaTrack {
    
    let id: String, title: String, artistName: String
    let type: MediaType
    let artwork: MusicArtwork
    let duration: TimeInterval
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.artistName = attributes["artistName"].stringValue
        self.artwork = MusicArtwork(data: attributes["artwork"])
        self.duration = TimeInterval(truncating: Int(Int(truncating: attributes["durationInMillis"].numberValue) + 1000) / Int(1000) as NSNumber)
    }
    
}
