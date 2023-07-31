//
//  MediaBrowseData.swift
//  Cider
//
//  Created by Sherlock LUK on 29/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaBrowseData {
    
    let name: String
    let id: String
    
    init(data: JSON) {
        let attributes = data["attributes"]
        
        self.id = attributes["id"].stringValue
        self.name = attributes["name"].stringValue
    }
    
}
