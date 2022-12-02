//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

enum RootNavigationType : String {
    
    case Home = "Home",
    Library = "Library",
    AnyView = "Any"
    
}

struct DetailedViewParams {
    
    let mediaItem: MusicItem
    let geometryMatching: Namespace.ID
    let originalSize: CGSize
    
}

class NavigationModal : ObservableObject {
    
    @Published var currentRootStack: RootNavigationType = .Home {
        didSet {
            self.isInDetailedView = false
        }
    }
    @Published var detailedViewParams: DetailedViewParams? = nil {
        didSet {
            if detailedViewParams != nil {
                self.isInDetailedView = true
            }
        }
    }
    @Published var isInDetailedView: Bool = false {
        didSet {
            if !isInDetailedView {
                detailedViewParams = nil
            }
        }
    }
    
}
