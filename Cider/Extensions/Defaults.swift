//
//  Defaults.swift
//  Cider
//
//  Created by Sherlock LUK on 25/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Defaults

enum AudioQuality: Int {
    case Standard = 65, High = 256
}

extension Defaults.Keys {
    
    static let audioQuality = Key<Int>("audioQuality", default: 256)
    
    #if DEBUG
    static let debugOpenWebInspectorAutomatically = Key<Bool>("openWebInspectorAutomatically", default: false)
    static let debugHideFrequentWSRequests = Key<Bool>("hideFrequentWSRequests", default: true)
    #endif
    
}
