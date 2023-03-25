//
//  Collection.swift
//  Cider
//
//  Created by Sherlock LUK on 25/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
