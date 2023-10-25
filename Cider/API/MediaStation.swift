//
//  MediaEditorialElement.swift
//  Cider
//
//  Created by Sherlock LUK on 18/10/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaStation {
    
    let id: String
    
    init(data: JSON) {
        let item = data["relationships"]["contents"]["data"].arrayValue.first
        
        self.id = item["id"].stringValue
    }
    
}
