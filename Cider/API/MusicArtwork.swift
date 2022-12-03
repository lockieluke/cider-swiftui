//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MusicArtwork {
    
    let width: Int
    let height: Int
    let rawUrl: String
    let bgColour: NSColor
    
    init(data: JSON) {
        self.width = data["width"].intValue
        self.height = data["height"].intValue
        self.rawUrl = data["url"].stringValue
        self.bgColour = NSColor(hex: data["bgColor"].stringValue)
    }
    
    func getUrl(_ dimension: CGSize) -> URL {
        return URL(string: self.rawUrl.replacingOccurrences(of: "{w}", with: dimension.width.formatted()).replacingOccurrences(of: "{h}", with: dimension.height.formatted()))!
    }
    
    func getUrl(width: Int, height: Int) -> URL {
        return self.getUrl(CGSize(width: width, height: height))
    }
    
}
