//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

enum MediaType: String {
    
    case Playlist = "playlists",
         Album = "albums",
         AnyMedia = "any",
         Song = "songs",
         Artist = "artists"
    
}

enum MediaDynamic {
    case mediaTrack(MediaTrack)
    case mediaItem(MediaItem)
}

enum PlaylistType: String {
    case PersonalMix = "personal-mix"
}
