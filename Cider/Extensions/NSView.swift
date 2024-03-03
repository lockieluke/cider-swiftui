//
//  NSView.swift
//  Cider
//
//  Created by Sherlock LUK on 03/03/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import AppKit

public extension NSView {
    
    func bitmapImage() -> NSImage? {
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        cacheDisplay(in: bounds, to: rep)
        guard let cgImage = rep.cgImage else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
    
}
