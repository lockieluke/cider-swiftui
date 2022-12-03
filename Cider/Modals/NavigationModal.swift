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

struct NavigationActions {
    
    var enableBack = false {
        didSet {
            if !enableBack {
                self.backAction = nil
            }
        }
    }
    var enableForward = false {
        didSet {
            if !enableForward {
                self.forwardAction = nil
            }
        }
    }
    var backAction: (() -> Void)? = nil
    var forwardAction: (() -> Void)? = nil
    
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
                self.navigationActions.enableBack = true
            }
        }
    }
    @Published var isInDetailedView: Bool = false {
        didSet {
            if !isInDetailedView {
                self.detailedViewParams = nil
                self.navigationActions.enableBack = false
            }
        }
    }
    
    @Published var navigationActions = NavigationActions()
    
}
