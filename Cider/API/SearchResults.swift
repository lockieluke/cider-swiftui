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
    
    let albums: [MediaItem]?
    let tracks: [MediaTrack]?
    let artists: [MediaArtist]?
    let playlists: [MediaPlaylist]?
    
    var isEmpty: Bool {
        get {
            return albums.isNilOrEmpty && tracks.isNilOrEmpty && artists.isNilOrEmpty && playlists.isNilOrEmpty
        }
    }
    
    init(data: JSON) {
        self.albums = data["albums"]["data"].array?.compactMap { MediaItem(data: $0) }
        self.tracks = data["songs"]["data"].array?.compactMap { MediaTrack(data: $0) }
        self.artists = data["artists"]["data"].array?.compactMap { MediaArtist(data: $0) }
        self.playlists = data["playlists"]["data"].array?.compactMap { MediaPlaylist(data: $0) }
    }
    
}
