//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MusicArtwork {
    
    let width: Int
    let height: Int
    let url: String
    
    init(data: JSON) {
        self.width = data["width"].intValue
        self.height = data["height"].intValue
        self.url = data["url"].stringValue
    }
    
}
