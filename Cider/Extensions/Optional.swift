//
//  Optional.swift
//  Cider
//
//  Created by Sherlock LUK on 17/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

extension Optional where Wrapped: Collection {
    var isNilOrEmpty: Bool {
        switch self {
            case .some(let collection):
                return collection.isEmpty
            case .none:
                return true
        }
    }
}
