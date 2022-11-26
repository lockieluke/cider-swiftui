//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class AppWindowModal : ObservableObject {

    @Published public var windowSize = CGSize()
    @Published public var nsWindow: NSWindow?
    
    init () {
        
    }
    
}
