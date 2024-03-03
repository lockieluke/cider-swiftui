//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Defaults
import KeychainAccess

struct NavigationContainer: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var searchModal: SearchModal
#if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
#endif
    
    @State private var isAdjustingSidebar: Bool = false
    
    var body: some View {
        PatchedGeometryReader { windowGeometry in
            HSplitView {
                SidebarPane()
                    .frame(width: navigationModal.shouldHideSidebar ? .zero : navigationModal.showSidebar ? nil : .zero)
                    .animation(isAdjustingSidebar ? .none : .interactiveSpring)
                    .overlay {
                        GeometryReader { geometry in
                            Color.clear
                                .onChange(of: geometry.size) { newSize in
                                    // Save sidebar width here
                                    let newWidth = newSize.width
                                    if newWidth != .zero && newWidth != 0 {
                                        self.isAdjustingSidebar = true
                                        Defaults[.sidebarWidth] = Double(newWidth)
                                        // TODO: Disable animation when sidebar is being adjusted
                                        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                                            self.isAdjustingSidebar = false
                                        }
                                    }
                                }
                        }
                    }
                
                ZStack {
                    if self.mkModal.isAuthorised {
                        let currentRootStack = navigationModal.currentRootStack
                        ForEach(navigationModal.viewsStack, id: \.id) { viewStack in
                            let isPresent = viewStack.isPresent
                            let viewStackOrigin = viewStack.rootStackOrigin ?? .AnyView
                            let shouldUpperStackShow = isPresent && currentRootStack == viewStackOrigin
                            
                            switch viewStack.params {
                                
                            case .rootViewParams:
                                Group {
                                    HomeView()
                                        .hideWithoutDestroying(currentRootStack != .Home || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Home }).count > 1)
                                    
                                    if navigationModal.hasLoadedRootStack(.ListenNow) {
                                        ListenNowView()
                                            .hideWithoutDestroying(currentRootStack != .ListenNow || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .ListenNow }).count > 0)
                                    }
                                    
                                    if navigationModal.hasLoadedRootStack(.Browse) {
                                        BrowseView()
                                            .hideWithoutDestroying(currentRootStack != .Browse || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Browse }).count > 0)
                                    }
                                    
                                    if navigationModal.hasLoadedRootStack(.Radio) {
                                        RadioView()
                                            .hideWithoutDestroying(currentRootStack != .Radio || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Radio }).count > 0)
                                    }
                                    
                                    if navigationModal.hasLoadedRootStack(.RecentlyAdded) {
                                        RecentlyAddedView()
                                            .hideWithoutDestroying(currentRootStack != .RecentlyAdded || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .RecentlyAdded }).count > 0)
                                    }
                                    
                                    if navigationModal.hasLoadedRootStack(.Songs) {
                                        SongsView()
                                            .hideWithoutDestroying(currentRootStack != .Songs || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Songs }).count > 0)
                                    }
                                    
                                    if navigationModal.hasLoadedRootStack(.Albums) {
                                        AlbumsView()
                                            .hideWithoutDestroying(currentRootStack != .Albums || navigationModal.viewsStack.filter ({ $0.rootStackOrigin == .Albums }).count > 0)
                                    }
                                }
                                
                            case .detailedViewParams(let detailedViewParams):
                                DetailedView(detailedViewParams: detailedViewParams)
                                    .opacity(shouldUpperStackShow ? 1 : 0)
                                    .allowsHitTesting(shouldUpperStackShow)
                                    .transition(.opacity.animation(.spring))
                                
                            case .artistViewParams(let artistViewParams):
                                ArtistView(params: artistViewParams)
                                    .hideWithoutDestroying(!shouldUpperStackShow)
                                    .allowsHitTesting(shouldUpperStackShow)
                                    .transition(.opacity.animation(.spring))
                                
                            default:
                                Color.clear
                            }
                            
                        }
                        .hideWithoutDestroying(searchModal.shouldDisplaySearchPage)
                        .zIndex(0)
                        
                        if searchModal.shouldDisplaySearchPage && !searchModal.currentSearchText.isEmpty {
                            SearchView()
                                .transition(.opacity.animation(.spring().speed(2)))
                                .zIndex(1)
                                .onChange(of: self.navigationModal.currentlyPresentViewStackIndex) { _ in
                                    self.searchModal.shouldDisplaySearchPage = false
                                }
                                .onDisappear {
                                    self.searchModal.searchResults = nil
                                }
                        }
                        
                        if navigationModal.showQueue {
                            QueueView()
                                .transition(.move(edge: .trailing))
                                .zIndex(1)
                        }
                        
                        if navigationModal.showLyrics {
                            LyricsPaneView()
                                .transition(.move(edge: .trailing))
                                .zIndex(1)
                        }
                    } else {
                        if (try? Keychain().get("mk-token")).isNil || !mkModal.isAuthorised {
                            NativeComponent(authModal.webview)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .layoutPriority(1)
                .animation(.none, value: navigationModal.showSidebar)
            }
            .onChange(of: navigationModal.currentRootStack) { currentRootStack in
                self.navigationModal.loadedRootStacks.insert(currentRootStack)
            }
            .onChange(of: windowGeometry.size) { size in
                self.navigationModal.shouldHideSidebar = size.width < 1100
            }
            .padding(.top, 45)
            .padding(.bottom, 100)
        }
        .enableInjection()
    }
}

struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer()
    }
}
