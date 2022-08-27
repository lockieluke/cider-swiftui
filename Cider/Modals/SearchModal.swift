//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class SearchModal : ObservableObject {
    
    public static let shared = SearchModal()
    
    @Published public var currentSearchText: String = ""
    
    init() {
        
    }
    
}
