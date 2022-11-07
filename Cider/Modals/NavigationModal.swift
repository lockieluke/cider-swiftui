//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

enum RootNavigationType : String {
    
    case Home = "Home",
    Library = "Library",
    AnyView = "Any"
    
}

class NavigationModal : ObservableObject {
    
    @Published var currentRootStack: RootNavigationType = .Home
    
}
