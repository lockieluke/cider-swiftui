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

enum NavigationStackType {
    
    case Home, Media
    
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

    var backAction: (() -> Void)? = nil
    
    mutating func reset() {
        self.enableBack = false
    }
    
}

struct NavigationStack {
    
    let stackType: NavigationStackType
    let id = UUID()
    var rootStackOrigin: RootNavigationType? = .AnyView
    var isPresent: Bool = true
    var params: Any?
    
}

class NavigationModal : ObservableObject {
    
    // segmented control state
    @Published var currentRootStack: RootNavigationType = .Home
    
    @Published var viewsStack: [NavigationStack] = [] {
        didSet {
            let presentIndex = viewsStack.firstIndex(where: { viewStack in viewStack.isPresent }) ?? 0
            self.navigationActions.reset()
            if viewsStack.count != 1 {
                if viewsStack.indices.contains(viewsStack.indices.last ?? 0) {
                    self.navigationActions.enableBack = true
                    self.navigationActions.backAction = {
                        self.viewsStack.removeLast()
                        self.viewsStack[self.viewsStack.endIndex - 1].isPresent = true
                    }
                }
            }
            
            self.currentlyPresentViewStack = viewsStack.first(where: { viewStack in viewStack.isPresent })
            self.currentlyPresentViewStackIndex = presentIndex
        }
    }
    
    func appendViewStack(_ viewStack: NavigationStack, backAction: (() -> Void)? = nil) {
        var modifyingViewStack = viewStack
        modifyingViewStack.rootStackOrigin = self.currentRootStack
        self.viewsStack.indices.forEach { index in
            self.viewsStack[index].isPresent = false
        }
        self.viewsStack.append(modifyingViewStack)
    }
    
    @Published var currentlyPresentViewStack: NavigationStack?
    @Published var currentlyPresentViewStackIndex: Int?
    
    @Published var navigationActions = NavigationActions()
    
}
