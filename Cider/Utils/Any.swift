//
//  Any.swift
//  Cider
//
//  Created by Sherlock LUK on 28/08/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

func unwrapAny(_ any: Any) -> Any {
    let mi = Mirror(reflecting: any)
    if mi.displayStyle != Mirror.DisplayStyle.optional {
        return any
    }

    if mi.children.count == 0 { return NSNull() }
    let (_, some) = mi.children.first!
    return some
}
