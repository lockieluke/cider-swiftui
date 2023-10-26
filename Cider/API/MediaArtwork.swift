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
    
    func getUrl(_ dimension: CGSize, kind: String = "bb", format: String = "jpg") -> URL {
        return URL(string: self.rawUrl.replacingOccurrences(of: "{w}", with: String(format: "%.0f", dimension.width)).replacingOccurrences(of: "{h}", with: String(format: "%.0f", dimension.height)).replacingOccurrences(of: "bb.", with: "\(kind).").replacingOccurrences(of: "{c}", with: kind).replacingOccurrences(of: "{f}", with: format)) ?? Bundle.main.url(forResource: "MissingArtwork", withExtension: "png")!
    }
    
    func getUrl(width: Int, height: Int, kind: String = "bb", format: String = "jpg") -> URL {
        return self.getUrl(CGSize(width: width, height: height), kind: kind, format: format)
    }
    
    func getUrlWithDefaultSize(kind: String = "bb", format: String = "jpg") -> URL {
        return self.getUrl(CGSize(width: self.width, height: self.height), kind: kind, format: format)
    }
    
}
