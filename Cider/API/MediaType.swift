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
         Artist = "artists",
         Catalog = "catalog"
    
}

enum MediaDynamic {
    case mediaTrack(MediaTrack), mediaItem(MediaItem), mediaPlaylist(MediaPlaylist)
    
    static func fromPlaylists(_ playlists: [MediaPlaylist]) -> [MediaDynamic] {
        return playlists.map { MediaDynamic.mediaPlaylist($0) }
    }
    
    static func fromMediaItems(_ mediaItems: [MediaItem]) -> [MediaDynamic] {
        return mediaItems.map { MediaDynamic.mediaItem($0) }
    }
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
    
    var title: String {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.title
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.title
            
        case .mediaPlaylist(let mediaPlaylist):
            return mediaPlaylist.title
            
        }
    }
    
    var artwork: MediaArtwork {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.artwork
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.artwork
            
        case .mediaPlaylist(let mediaPlaylist):
            return mediaPlaylist.artwork
            
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
