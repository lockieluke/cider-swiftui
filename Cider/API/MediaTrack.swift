//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MediaTrack {
    
    let id: String, title: String, artistName: String
    let type: MediaType
    let artwork: MediaArtwork
    let contentRating: String
    let duration: TimeInterval
    var artistsData: [MediaAny] = []
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.type = MediaType(rawValue: data["type"].stringValue) ?? .AnyMedia
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.artistName = attributes["artistName"].stringValue
        self.artwork = MediaArtwork(data: attributes["artwork"])
        self.contentRating = attributes["contentRating"].stringValue
        self.duration = TimeInterval(truncating: Int(Int(truncating: attributes["durationInMillis"].numberValue) + 1000) / Int(1000) as NSNumber)
        
        let artistsData = data["relationships"]["artists"]["data"].arrayValue
        artistsData.forEach { artistData in
            self.artistsData.append(MediaAny(id: artistData["id"].stringValue, type: .Artist, href: artistData["href"].stringValue))
        }
    }
    
}
