//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct NavigationContainer: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var searchModal: SearchModal
    #if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    #endif
    
    var body: some View {
        ZStack {
            if self.mkModal.isAuthorised {
                ForEach(navigationModal.viewsStack, id: \.id) { viewStack in
                    let isPresent = viewStack.isPresent
                    let currentRootStack = navigationModal.currentRootStack
                    let viewStackOrigin = viewStack.rootStackOrigin ?? .AnyView
                    let shouldUpperStackShow = isPresent && currentRootStack == viewStackOrigin
                    
                    switch viewStack.params {
                        
                    case .homeViewParams:
                        HomeView()
                            .environmentObject(mkModal)
                            .environmentObject(personalisedData)
                            .environmentObject(navigationModal)
                            .environmentObject(ciderPlayback)
                            .hideWithoutDestroying(currentRootStack != .Home)
                            .allowsHitTesting(shouldUpperStackShow)
                        
                    case .detailedViewParams(let detailedViewParams):
                        DetailedView(detailedViewParams: detailedViewParams)
                            .environmentObject(mkModal)
                            .environmentObject(navigationModal)
                            .environmentObject(ciderPlayback)
                            .opacity(shouldUpperStackShow ? 1 : 0)
                            .allowsHitTesting(shouldUpperStackShow)
                        
                    case .artistViewParams(let artistViewParams):
                        ArtistView(params: artistViewParams)
                            .environmentObject(mkModal)
                            .environmentObject(ciderPlayback)
                            .environmentObject(navigationModal)
                        #if os(macOS)
                            .environmentObject(nativeUtilsWrapper)
                        #endif
                            .hideWithoutDestroying(!shouldUpperStackShow)
                            .allowsHitTesting(shouldUpperStackShow) 
                    
                    default:
                        Color.clear
                    }
                    
                }
                .zIndex(0)
                .hideWithoutDestroying(searchModal.shouldDisplaySearchPage)
                
                if searchModal.shouldDisplaySearchPage && !searchModal.currentSearchText.isEmpty {
                    SearchView()
                        .transition(.opacity.animation(.spring().speed(2)))
                        .zIndex(1)
                        .onChange(of: self.navigationModal.currentlyPresentViewStackIndex) { _ in
                            self.searchModal.shouldDisplaySearchPage = false
                        }
                        .environmentObject(searchModal)
                        .environmentObject(mkModal)
                        .environmentObject(navigationModal)
                        .environmentObject(ciderPlayback)
                        .onDisappear {
                            self.searchModal.searchResults = nil
                        }
                }
                
                if navigationModal.showQueue {
                    QueueView()
                        .environmentObject(ciderPlayback)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                }
                
                if navigationModal.showLyrics {
                    LyricsPaneView()
                        .environmentObject(mkModal)
                        .environmentObject(ciderPlayback)
                    #if os(macOS)
                        .environmentObject(nativeUtilsWrapper)
                    #endif
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                }
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 100)
        .enableInjection()
    }
}

struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer()
    }
}
