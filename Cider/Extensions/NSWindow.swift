//
//  NSWindow.swift
//  Cider
//
//  Created by Sherlock LUK on 21/09/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import AppKit

extension NSWindow {
    public func setFrameOriginToPositionWindowInCenterOfScreen() {
        if let screenSize = screen?.frame.size {
            self.setFrameOrigin(NSPoint(x: (screenSize.width-frame.size.width)/2, y: (screenSize.height-frame.size.height)/2))
        }
    }
}
