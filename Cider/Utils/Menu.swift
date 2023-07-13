//
//  Menu.swift
//  Cider
//
//  Created by Sherlock LUK on 13/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import AppKit

class Menu {
    
    static func wrapMenuItem(_ menuItem: NSMenuItem) -> NSMenuItem {
        menuItem.target = self
        return menuItem
    }
    
}
