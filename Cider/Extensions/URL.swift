//
//  URL.swift
//  Cider
//
//  Created by Sherlock LUK on 27/06/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

extension URL {
    
    func open() {
        #if canImport(AppKit)
        NSWorkspace.shared.open(self)
        #elseif canImport(UIKit)
        UIApplication.shared.open(self)
        #endif
    }
    
}
