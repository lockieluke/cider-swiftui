//
//  MediaDescription.swift
//  Cider
//
//  Created by Sherlock LUK on 14/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct MediaDescription {
    
    let standard: String
    let short: String
    
    init(data: JSON) {
        self.standard = data["standard"].stringValue
        self.short = data["short"].stringValue
    }
    
}
