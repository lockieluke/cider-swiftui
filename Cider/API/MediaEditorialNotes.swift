//
//  MediaEditorialNotes.swift
//  Cider
//
//  Created by Sherlock LUK on 18/10/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaEditorialNotes {
    
    let name: String
    let short: String
    let tagline: String
    
    init(data: JSON) {
        self.name = data["name"].stringValue
        self.short = data["short"].stringValue
        self.tagline = data["tagline"].stringValue
    }
    
}
