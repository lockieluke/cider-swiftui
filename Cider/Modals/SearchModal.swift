//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class SearchModal : ObservableObject {
    
    @Published var currentSearchText: String = ""
    @Published var isFocused: Bool = false
    @Published var isLoadingResults: Bool = false
    @Published var shouldDisplaySearchPage: Bool = false
    @Published var searchResults: SearchResults? = nil
    
    init() {
        
    }
    
}
