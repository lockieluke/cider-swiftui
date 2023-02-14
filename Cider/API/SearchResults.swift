//
//  SearchResults.swift
//  Cider
//
//  Created by Sherlock LUK on 13/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct SearchResults {
    
    let albums: [MediaItem]
    let tracks: [MediaTrack]
    let artists: [MediaArtist]
    
    init(data: JSON) {
        self.albums = data["albums"]["data"].arrayValue.map { MediaItem(data: $0) }
        self.tracks = data["songs"]["data"].arrayValue.map { MediaTrack(data: $0) }
        self.artists = data["artists"]["data"].arrayValue.map { MediaArtist(data: $0) }
    }
    
}
