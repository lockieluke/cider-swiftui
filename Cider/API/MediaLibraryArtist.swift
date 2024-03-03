//
//  MediaLibraryArtist.swift
//  Cider
//
//  Created by Sherlock LUK on 03/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaLibraryArtist {
    
    let id: String, artistName: String, artistId: String
    let artwork: MediaArtwork
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.artistName = data["attributes"]["name"].stringValue
        
        let realData = data["relationships"]["catalog"]["data"].arrayValue.first ?? []
        let attributes = realData["attributes"]
        
        self.artistId = realData["id"].stringValue
        self.artwork = MediaArtwork(data: attributes["artwork"])
    }
    
}
