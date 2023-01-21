//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import AppKit

class AppWindowModal : ObservableObject {

    @Published var nsWindow: NSWindow?
    @Published var isFocused: Bool = false
    @Published var isVisibleInViewport: Bool = false
    
    init () {
        
    }
    
}
