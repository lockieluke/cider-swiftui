//
//  MediaBrowseData.swift
//  Cider
//
//  Created by Sherlock LUK on 29/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct EditorialKind: Hashable, Equatable {
    let rawValue: String
    static let unknown = EditorialKind(rawValue: "unknown")
}

struct BrowseItemAttributes: Hashable {
    let designBadge: String
    let name: String
    let id: String
    let kind: String
    let artistName: String
    let url: String
    let artistUrl: String
    let subscriptionHero: String
    let plainEditorialNotes: String
}

struct MediaBrowseData {
    
    let id: String
    let items: [BrowseItemAttributes]
    let kind: EditorialKind
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.kind = EditorialKind(rawValue: data["attributes"]["editorialElementKind"].string ?? "unknown")
        
        self.items = data["relationships"]["children"]["data"].array?.compactMap { child -> BrowseItemAttributes? in
            let badge = child["attributes"]["designBadge"].string ?? ""
            let meta = child["relationships"]["contents"]["data"].array?.first?["attributes"]
            
            guard let meta = meta else { return nil }
                        
            let name = meta["name"].string ?? meta["designTag"].string ?? ""
            let artist = meta["curatorName"].string ?? meta["designTag"].string ?? meta["artistName"].string ?? ""
            
            let id = meta["playParams"]["id"].string ?? ""
            let kind = meta["playParams"]["kind"].string ?? ""
            
            let url = meta["url"].string ?? ""
            let artistUrl = meta["artistUrl"].string ?? ""
            
            // we're following my hierarchy :)
            
            var subscriptionHero: String
            
            if let url = meta["editorialArtwork"]["subscriptionHero"]["url"].string, !url.isEmpty {
                let width = meta["editorialArtwork"]["subscriptionHero"]["width"].intValue
                let height = meta["editorialArtwork"]["subscriptionHero"]["height"].intValue
                subscriptionHero = url.replacingOccurrences(of: "{w}", with: "\(width)")
                    .replacingOccurrences(of: "{h}", with: "\(height)")
                    .replacingOccurrences(of: "{f}", with: "jpg")
            } else if let url = meta["editorialArtwork"]["emailFeature"]["url"].string, !url.isEmpty {
                let width = meta["editorialArtwork"]["emailFeature"]["width"].intValue
                let height = meta["editorialArtwork"]["emailFeature"]["height"].intValue
                subscriptionHero = url.replacingOccurrences(of: "{w}", with: "\(width)")
                    .replacingOccurrences(of: "{h}", with: "\(height)")
                    .replacingOccurrences(of: "{f}", with: "jpg")
            } else if let url = meta["editorialArtwork"]["subscriptionCover"]["url"].string, !url.isEmpty {
                let width = meta["editorialArtwork"]["subscriptionCover"]["width"].intValue
                let height = meta["editorialArtwork"]["subscriptionCover"]["height"].intValue
                subscriptionHero = url.replacingOccurrences(of: "{w}", with: "\(width)")
                    .replacingOccurrences(of: "{h}", with: "\(height)")
                    .replacingOccurrences(of: "{f}", with: "jpg")
            } else {
                let url = meta["artwork"]["url"].string ?? ""
                let width = meta["artwork"]["width"].intValue
                let height = meta["artwork"]["height"].intValue
                subscriptionHero = url.replacingOccurrences(of: "{w}", with: "\(width)")
                    .replacingOccurrences(of: "{h}", with: "\(height)")
                    .replacingOccurrences(of: "{f}", with: "jpg")
            }
            
            let plainEditorialNotes = meta["plainEditorialNotes"]["short"].string ?? ""
            
            return BrowseItemAttributes(designBadge: badge, name: name, id: id, kind: kind, artistName: artist, url: url, artistUrl: artistUrl, subscriptionHero: subscriptionHero, plainEditorialNotes: plainEditorialNotes)
        } ?? []
    }
}
