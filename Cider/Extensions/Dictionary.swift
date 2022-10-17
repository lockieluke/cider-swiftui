//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension Dictionary {
    mutating func merge(dict: [Key: Value]){
        for (k, v) in dict {
            updateValue(v, forKey: k)
        }
    }
}
