//
//  MediaRadioData.swift
//  Cider
//
//  Created by Sherlock LUK on 15/10/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

// A row in the radio page
struct MediaRadioData {
    
    let id: String
    let name: String
    let kind: EditorialKind
    let items: [MediaDynamic]
    
    init(data: JSON) {
        let attributes = data["attributes"]
        
        self.id = data["id"].stringValue
        self.name = attributes["name"].stringValue
        self.kind = EditorialKind(rawValue: attributes["editorialElementKind"].string ?? "unknown")
        
        let items = data["relationships"]["children"]["data"].array ?? data["relationships"]["contents"]["data"].arrayValue
        self.items = items.compactMap { item in
            let item = item["relationships"]["contents"]["data"].arrayValue.first ?? item
            let type = MediaType(rawValue: item["type"].stringValue)
            
            if type == .Station {
                return .mediaStation(MediaStation(data: item))
            }
            
            if type == .AppleCurator {
                return .mediaAppleCurator(MediaAppleCurator(data: item))
            }
            
            return nil
        }
    }
    
}
