//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

class AppWindowModal : ObservableObject {

    #if canImport(AppKit)
    @Published var nsWindow: NSWindow?
    #endif
    @Published var isFocused: Bool = false
    @Published var isFullscreen: Bool = false
    @Published var isVisibleInViewport: Bool = false
    
    init () {
        
    }
    
}
