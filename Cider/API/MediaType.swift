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
         Catalog = "catalog",
         Station = "stations",
         AppleCurator = "apple-curators"
    
}

enum MediaDynamic {
    case mediaTrack(MediaTrack), mediaItem(MediaItem), mediaPlaylist(MediaPlaylist), mediaStation(MediaStation), mediaAppleCurator(MediaAppleCurator)
    
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
            
        case .mediaStation(let mediaStation):
            return mediaStation.id
            
        case .mediaAppleCurator(let mediaAppleCurator):
            return mediaAppleCurator.id
            
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
            
        case .mediaStation(_):
            return "stations"
            
        case .mediaAppleCurator(_):
            return "apple-curators"
            
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
            
        case .mediaStation(let mediaStation):
            return mediaStation.title
            
        case .mediaAppleCurator(let mediaAppleCurator):
            return mediaAppleCurator.title
            
        }
    }
    
    var contentRating: String {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.contentRating
            
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.contentRating
            
        case .mediaPlaylist(_):
            return ""
            
        case .mediaStation(_):
            return ""
            
        case .mediaAppleCurator(_):
            return ""
            
        }
    }
    
    var albumId: String? {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.id
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.albumId
            
        case .mediaPlaylist(_):
            return nil
            
        case .mediaStation(_):
            return nil
            
        case .mediaAppleCurator(let mediaAppleCurator):
            return nil
            
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
            
        case .mediaStation(let mediaStation):
            return mediaStation.artwork
            
        case .mediaAppleCurator(let mediaAppleCurator):
            return mediaAppleCurator.artwork
            
        }
    }
    
    var artistName: String {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.artistName
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.artistName
            
        case .mediaPlaylist(let mediaPlaylist):
            return mediaPlaylist.curatorName
            
        case .mediaStation(_):
            return ""
            
        case .mediaAppleCurator(let mediaAppleCurator):
            return mediaAppleCurator.hostName
            
        }
    }
    
    var playParams: PlayParams? {
        switch self {
            
        case .mediaItem(let mediaItem):
            return mediaItem.playParams
            
        case .mediaTrack(let mediaTrack):
            return mediaTrack.playParams
            
        case .mediaPlaylist(let mediaPlaylist):
            return mediaPlaylist.playParams
            
        case .mediaStation(let mediaStation):
            return mediaStation.playParams
            
        case .mediaAppleCurator(_):
            return nil
            
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
