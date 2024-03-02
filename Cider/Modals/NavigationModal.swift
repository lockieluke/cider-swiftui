//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftUI
import Defaults

enum RootNavigationType {
    
    case Home, ListenNow, Browse, Radio, Library, RecentlyAdded, Songs, Playlist, AnyView
    
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
    let animationId: String?
    let originalSize: CGSize
    let coverKind: String
    
    init(item: MediaDynamic, geometryMatching: Namespace.ID? = nil, animationId: String? = nil, originalSize: CGSize, coverKind: String = "bb") {
        self.item = item
        self.geometryMatching = geometryMatching
        self.animationId = animationId
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

struct NavigationStack {
    
    let id = UUID()
    var rootStackOrigin: RootNavigationType? = .AnyView
    var isPresent: Bool = true
    var params: NavigationDynamicParams?
    
}

class NavigationModal : ObservableObject {
    
    @Published var currentRootStack: RootNavigationType = .Home
    @Published var loadedRootStacks: Set<RootNavigationType> = [.Home]
    
    // View Stack in each sidebar item screen
    @Published var viewsStack: [NavigationStack] = [] {
        didSet {
            let presentIndex = viewsStack.firstIndex(where: { viewStack in viewStack.isPresent }) ?? 0
            
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
            if self.viewsStack[index].rootStackOrigin == self.currentRootStack {
                self.viewsStack[index].isPresent = false
            }
        }
        self.viewsStack.append(modifyingViewStack)
    }
    
    func replaceCurrentViewStack(_ viewStack: NavigationStack) {
        if self.viewsStack.last?.rootStackOrigin == self.currentRootStack {
            self.viewsStack.removeLast()
        }
        var modifyingViewStack = viewStack
        modifyingViewStack.rootStackOrigin = self.currentRootStack
        self.viewsStack.indices.forEach { index in
            if self.viewsStack[index].rootStackOrigin == self.currentRootStack {
                self.viewsStack[index].isPresent = false
            }
        }
        self.viewsStack.append(modifyingViewStack)
    }
    
    func resetToRoot(rootStack: RootNavigationType) {
        let viewStackToKeep = self.viewsStack[0]
        self.viewsStack = [viewStackToKeep] + self.viewsStack.filter { viewStack in viewStack.rootStackOrigin == rootStack }
        self.viewsStack[0].isPresent = true
    }
    
    func goBack() {
        if let indexToRemove = self.viewsStack.lastIndex(where: { viewStack in viewStack.rootStackOrigin == self.currentRootStack }) {
            self.viewsStack.remove(at: indexToRemove)
        }
        if self.viewsStack.count > 1 {
            self.viewsStack[self.viewsStack.count - 1].isPresent = true
        }
    }
    
    @Published var currentlyPresentViewStack: NavigationStack?
    @Published var currentlyPresentViewStackIndex: Int?
    @Published var currentlyPresentViewType: NavigationStackType?
    
    var isBackAvailable: Bool {
        return self.viewsStack.filter ({ $0.rootStackOrigin == self.currentRootStack }).count > (self.currentRootStack == .Home ? 1 : 0) && self.currentRootStack != .Playlist
    }
    
    @Published var showQueue: Bool = false
    @Published var showLyrics: Bool = false
    @Published var showSidebar: Bool = false {
        didSet {
            Defaults[.showSidebarAtLaunch] = self.showSidebar
        }
    }
    @Published var shouldHideSidebar: Bool = false
    
    @Published var inOnboardingExperience: Bool = false
    @Published var isDonateViewPresent: Bool = false
    @Published var isAboutViewPresent: Bool = false
    @Published var isChangelogsViewPresent: Bool = ProcessInfo.processInfo.arguments.contains("-show-changelogs")
    @Published var isAnalyticsPersuationPresent: Bool = false
    @Published var displayDisableButtonInAnalyticsPersuation: Bool = false
    
}
