//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI

enum RootNavigationType : String {
    
    case Home = "Home",
         ListenNow = "ListenNow",
         Library = "Library",
         Browse = "Browse",
         AnyView = "Any"
    
}

enum NavigationStackType {
    
    case Root, Media, Artist
    
}

enum NavigationDynamicParams: Equatable {
    
    // logic to verify if the two pages are essentially the same page so the new one doesn't have to be pushed to the stack again
    static func == (lhs: NavigationDynamicParams, rhs: NavigationDynamicParams) -> Bool {
        return lhs.value == rhs.value
    }
    
    var value: String {
        switch self {
        case .rootViewParams:
            return "home"
            
        case .detailedViewParams(let detailedViewParams):
            if case .mediaItem(let mediaItem) = detailedViewParams.item {
                return mediaItem.id
            } else if case .mediaPlaylist(let mediaPlaylist) = detailedViewParams.item {
                return mediaPlaylist.id
            }
            return ""
            
        case .artistViewParams(let artistViewParams):
            if let artist = artistViewParams.artist {
                return artist.id
            }
            
            if case let .mediaTrack(mediaTrack) = artistViewParams.originMediaItem {
                return mediaTrack.artistsData[artistViewParams.selectingArtistIndex].id
            }
            
            return artistViewParams.originMediaItem.debugDescription
        }
    }
    
    case detailedViewParams(DetailedViewParams), artistViewParams(ArtistViewParams), rootViewParams
}

struct DetailedViewParams {
    let item: MediaDynamic
    let geometryMatching: Namespace.ID?
    let originalSize: CGSize
    let coverKind: String
    
    init(item: MediaDynamic, geometryMatching: Namespace.ID?, originalSize: CGSize, coverKind: String = "bb") {
        self.item = item
        self.geometryMatching = geometryMatching
        self.originalSize = originalSize
        self.coverKind = coverKind
    }
}

struct ArtistViewParams {
    
    let originMediaItem: MediaDynamic?
    let artist: MediaArtist?
    let selectingArtistIndex: Int
    
    init(originMediaItem: MediaDynamic, selectingArtistIndex: Int = .zero) {
        self.originMediaItem = originMediaItem
        self.selectingArtistIndex = selectingArtistIndex
        self.artist = nil
    }
    
    init(artist: MediaArtist) {
        self.artist = artist
        self.originMediaItem = nil
        self.selectingArtistIndex = .zero
    }
    
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
    
    let id = UUID()
    var rootStackOrigin: RootNavigationType? = .AnyView
    var isPresent: Bool = true
    var params: NavigationDynamicParams?
    
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
                        withAnimation(.interactiveSpring()) {
                            self.viewsStack.removeLast()
                            self.viewsStack[self.viewsStack.endIndex - 1].isPresent = true
                        }
                    }
                }
            }
            
            let currentPresentViewStack = viewsStack.first(where: { viewStack in viewStack.isPresent })
            self.currentlyPresentViewStack = currentPresentViewStack
            self.currentlyPresentViewStackIndex = presentIndex
            
            switch currentPresentViewStack?.params {
                
            case .rootViewParams:
                self.currentlyPresentViewType = .Root
                
            case .artistViewParams:
                self.currentlyPresentViewType = .Artist
                
            case .detailedViewParams:
                self.currentlyPresentViewType = .Media
                
            default:
                break
                
            }
        }
    }
    
    func appendViewStack(_ viewStack: NavigationStack, backAction: (() -> Void)? = nil) {
        if (viewStack.params == .rootViewParams && self.currentlyPresentViewType == .Root) || viewStack.params == self.currentlyPresentViewStack?.params {
            return
        }
        var modifyingViewStack = viewStack
        modifyingViewStack.rootStackOrigin = self.currentRootStack
        self.viewsStack.indices.forEach { index in
            self.viewsStack[index].isPresent = false
        }
        self.viewsStack.append(modifyingViewStack)
    }
    
    @Published var currentlyPresentViewStack: NavigationStack?
    @Published var currentlyPresentViewStackIndex: Int?
    @Published var currentlyPresentViewType: NavigationStackType?
    @Published var navigationActions = NavigationActions()
    
    @Published var showQueue: Bool = false
    @Published var showLyrics: Bool = false
    @Published var showSidebar: Bool = false
    
}
