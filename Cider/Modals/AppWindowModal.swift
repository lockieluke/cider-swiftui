//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class AppWindowModal : ObservableObject {
    
    public static let shared = AppWindowModal()
    
    @Published public var windowSize = CGSize()
    
    init () {
        
    }
    
}
