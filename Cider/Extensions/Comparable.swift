//
//  Comparable.swift
//  Cider
//
//  Created by Sherlock LUK on 16/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}
