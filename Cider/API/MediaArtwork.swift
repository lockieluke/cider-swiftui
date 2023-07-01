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
    
    func getUrl(_ dimension: CGSize) -> URL {
        return URL(string: self.rawUrl.replacingOccurrences(of: "{w}", with: dimension.width.formatted()).replacingOccurrences(of: "{h}", with: dimension.height.formatted())) ?? Bundle.main.url(forResource: "MissingArtwork", withExtension: "png")!
    }
    
    func getUrl(width: Int, height: Int) -> URL {
        return self.getUrl(CGSize(width: width, height: height))
    }
    
}
