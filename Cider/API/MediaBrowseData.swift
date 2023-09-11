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
    let editorialTitle: String
    let kind: EditorialKind
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.editorialTitle = data["attributes"]["name"].string ?? ""
        self.kind = EditorialKind(rawValue: data["attributes"]["editorialElementKind"].string ?? "unknown")
        
        if ["316", "385", "323"].contains(self.kind.rawValue) {
            self.items = MediaBrowseData.parseChildren(from: data)
        } else {
            self.items = MediaBrowseData.parseContents(from: data)
        }
    }
    
    // fuck you apple
    
    private static func parseChildren(from data: JSON) -> [BrowseItemAttributes] {
        return data["relationships"]["children"]["data"].array?.compactMap { child -> BrowseItemAttributes? in
            guard let meta = child["relationships"]["contents"]["data"].array?.first?["attributes"] else { return nil }
            return createBrowseItem(from: child, withMeta: meta)
        } ?? []
    }
    
    private static func parseContents(from data: JSON) -> [BrowseItemAttributes] {
        return data["relationships"]["contents"]["data"].array?.compactMap { child -> BrowseItemAttributes? in
            return createBrowseItem(from: child)
        } ?? []
    }
    
    private static func createBrowseItem(from child: JSON, withMeta meta: JSON? = nil) -> BrowseItemAttributes {
        let actualMeta = meta ?? child["attributes"]
        
        let badge = child["attributes"]["designBadge"].string ?? ""
        let name = actualMeta["name"].string ?? actualMeta["designTag"].string ?? ""
        let artist = actualMeta["curatorName"].string ?? actualMeta["designTag"].string ?? actualMeta["artistName"].string ?? ""
        let id = actualMeta["playParams"]["id"].string ?? ""
        let kind = actualMeta["playParams"]["kind"].string ?? ""
        let url = actualMeta["url"].string ?? ""
        let artistUrl = actualMeta["artistUrl"].string ?? ""
        let subscriptionHero = getArtwork(from: actualMeta)
        let plainEditorialNotes = actualMeta["plainEditorialNotes"]["short"].string ?? ""
        
        return BrowseItemAttributes(designBadge: badge, name: name, id: id, kind: kind, artistName: artist, url: url, artistUrl: artistUrl, subscriptionHero: subscriptionHero, plainEditorialNotes: plainEditorialNotes)
    }
    
    private static func getArtwork(from meta: JSON) -> String {
        let monosHierarchy = ["subscriptionHero", "emailFeature", "subscriptionCover", "artwork"]
        
        for artwork in monosHierarchy {
            if let url = meta["editorialArtwork"][artwork]["url"].string, !url.isEmpty {
                let width = meta["editorialArtwork"][artwork]["width"].intValue
                let height = meta["editorialArtwork"][artwork]["height"].intValue
                return url.replacingOccurrences(of: "{w}", with: "\(width)")
                    .replacingOccurrences(of: "{h}", with: "\(height)")
                    .replacingOccurrences(of: "{f}", with: "jpg")
            }
        }
        return ""
    }
}
