//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif
import SwiftyJSON

struct MediaEditorialArtwork {
    
    let subscriptionHero: MediaArtwork
    let brandLogo: MediaArtwork
    let subscriptionCover: MediaArtwork
    
    init(data: JSON) {
        self.subscriptionHero = MediaArtwork(data: data["subscriptionHero"])
        self.brandLogo = MediaArtwork(data: data["brandLogo"])
        self.subscriptionCover = MediaArtwork(data: data["subscriptionCover"])
    }
    
}

struct MediaArtwork {
    
    let width: Int
    let height: Int
    let rawUrl: String
    let bgColour: PlatformColor
    
    init(data: JSON) {
        self.width = data["width"].intValue
        self.height = data["height"].intValue
        self.rawUrl = data["url"].stringValue
        self.bgColour = PlatformColor(hex: data["bgColor"].stringValue)
    }
    
    static func getUrl(url: String, dimension: CGSize, kind: String = "bb", format: String = "webp") -> URL {
        return URL(string: url.replacingOccurrences(of: "{w}", with: String(format: "%.0f", dimension.width)).replacingOccurrences(of: "{h}", with: String(format: "%.0f", dimension.height)).replacingOccurrences(of: "bb.", with: "\(kind).").replacingOccurrences(of: "{c}", with: kind).replacingOccurrences(of: "{f}", with: format)) ?? Bundle.main.url(forResource: "MissingArtwork", withExtension: "png")!
    }
    
    func getUrl(_ dimension: CGSize, kind: String = "bb", format: String = "webp") -> URL {
        return MediaArtwork.getUrl(url: self.rawUrl, dimension: dimension, kind: kind, format: format)
    }
    
    func getUrl(width: Int, height: Int, kind: String = "bb", format: String = "webp") -> URL {
        return self.getUrl(CGSize(width: width, height: height), kind: kind, format: format)
    }
    
    func getUrlWithDefaultSize(kind: String = "bb", format: String = "webp") -> URL {
        return self.getUrl(CGSize(width: self.width, height: self.height), kind: kind, format: format)
    }
    
}
