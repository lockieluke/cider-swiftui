//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

protocol MediaDynamicType {}

enum MediaType: String {
    
    case Playlist = "playlists",
         Album = "albums",
         AnyMedia = "any",
         Song = "songs",
         Artist = "artists"
    
}

enum MediaDynamic {
    case mediaTrack(MediaTrack), mediaItem(MediaItem), mediaPlaylist(MediaPlaylist)
}

enum MediaRatings: Int {
    case Disliked = -1
    case Neutral = 0
    case Liked = 1
}

extension MediaDynamic: Identifiable, Hashable {
    
    var id: String {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.id
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.id
            
        case .mediaPlaylist(let mediaPlaylist):
            return mediaPlaylist.id
            
        }
    }
    
    var type: String {
        
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.type.rawValue
            
        case .mediaTrack( _):
            return "songs"
            
        case .mediaPlaylist( _):
            return "playlists"
            
        }
        
    }
    
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }
    
    public static func == (lhs: MediaDynamic, rhs: MediaDynamic) -> Bool {
        return lhs.id == rhs.id
    }
    
}

enum PlaylistType: String {
    case PersonalMix = "personal-mix", Editorial = "editorial", Unknown = "unknown"
}
