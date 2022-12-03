//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

struct MediaTrack {
    
    let id: String, title: String
    let duration: TimeInterval
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        
        let attributes = data["attributes"]
        self.title = attributes["name"].stringValue
        self.duration = TimeInterval(truncating: Int(Int(truncating: attributes["durationInMillis"].numberValue) + 1000) / Int(1000) as NSNumber)
    }
    
}
