//
//  NSScreen.swift
//  Cider
//
//  Created by Sherlock LUK on 26/08/2022.
//

import Foundation
import AppKit


extension NSScreen {
    
    static var activeScreen: NSScreen  {
        get {
            let mouseLocation = NSEvent.mouseLocation
            let screens = NSScreen.screens
            guard let screenWithMouse = (screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }) else {
                return NSScreen.main!
            }
            
            return screenWithMouse
        }
    }
}
