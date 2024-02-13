//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject
import Defaults

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
        HSplitView {
            SidebarPane()
                .frame(width: navigationModal.showSidebar ? nil : .zero)
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
                    ForEach(navigationModal.viewsStack, id: \.id) { viewStack in
                        let isPresent = viewStack.isPresent
                        let currentRootStack = navigationModal.currentRootStack
                        let viewStackOrigin = viewStack.rootStackOrigin ?? .AnyView
                        let shouldUpperStackShow = isPresent && currentRootStack == viewStackOrigin
                        
                        switch viewStack.params {
                            
                        case .rootViewParams:
                            Group {
                                HomeView()
                                    .opacity(currentRootStack != .Home || !isPresent ? 0 : 1)
                                    .hideWithoutDestroying(currentRootStack != .Home || !isPresent)
                                
                                ListenNowView()
                                    .hideWithoutDestroying(currentRootStack != .ListenNow || !isPresent)
                                
                                BrowseView()
                                    .hideWithoutDestroying(currentRootStack != .Browse || !isPresent)
                                
                                RadioView()
                                    .hideWithoutDestroying(currentRootStack != .Radio || !isPresent)
                            }
                            
                        case .detailedViewParams(let detailedViewParams):
                            DetailedView(detailedViewParams: detailedViewParams)
                                .opacity(shouldUpperStackShow ? 1 : 0)
                                .allowsHitTesting(shouldUpperStackShow)
                            
                        case .artistViewParams(let artistViewParams):
                            ArtistView(params: artistViewParams)
                                .hideWithoutDestroying(!shouldUpperStackShow)
                                .allowsHitTesting(shouldUpperStackShow)
                            
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
                    NativeComponent(authModal.webview)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .layoutPriority(1)
            .animation(.none, value: navigationModal.showSidebar)
        }
        .padding(.top, 45)
        .padding(.bottom, 100)
        .enableInjection()
    }
}

struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer()
    }
}
