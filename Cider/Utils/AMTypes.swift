//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

// Recommendations from /me/recommendations
struct AMRecommendations {
    var id: String
    var contents: [AMRecommendationSection]
}

enum AMResourceType: String {
    case Playlists = "playlists"
    case Albums = "album"
    case Unknown = "unknown"
}

struct AMArtwork {
    var url: String
    var size: NSSize
    var bgColour: NSColor
}

// Individual recommended album / song
struct AMMediaItem {
    var title: String
    var artwork: AMArtwork
}

struct AMRecommendationSection {
    var title: String
    var id: String
    var recommendations: [AMMediaItem] = []
}
