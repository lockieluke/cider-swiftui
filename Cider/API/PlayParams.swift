//
//  PlayParams.swift
//  Cider
//
//  Created by Monochromish on 12/09/23.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct PlayParams {
    let kind: String
    let id: String
    let versionHash: String?

    init(data: JSON) {
        self.kind = data["kind"].stringValue
        self.id = data["id"].stringValue
        self.versionHash = data["versionHash"].stringValue
    }
}
