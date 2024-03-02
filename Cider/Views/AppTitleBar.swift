//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct AppTitleBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
#if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
#endif
    
    private var titleBarHeight: CGFloat = 50
    
    var body: some View {
        ZStack {
            HStack {
                Spacer()
                    .frame(width: appWindowModal.isFullscreen ? 2 : 85)
                    .animation(.linear, value: appWindowModal.isFullscreen)
                
                Divider()
                    .frame(height: 25)
                    .isHidden(appWindowModal.isFullscreen)
                    .animation(.linear, value: appWindowModal.isFullscreen)
                
                if navigationModal.isBackAvailable && !searchModal.shouldDisplaySearchPage {
                    ActionButton(actionType: .Back) {
                        withAnimation(.interactiveSpring) {
                            self.navigationModal.goBack()
                        }
                    }
                }
                
                if !navigationModal.shouldHideSidebar {
                    ActionButton(actionType: .Library) {
                        self.navigationModal.showSidebar.toggle()
                    }
                }
                Spacer()
#if os(macOS)
                if ciderPlayback.nowPlayingState.playbackPipelineInitialised {
                    ActionButton(actionType: .AirPlay) {
                        Task {
                            guard let frame = self.appWindowModal.nsWindow?.frame else { return }
                            let supportsAirplay = await self.ciderPlayback.playbackEngine.openAirPlayPicker()
                            
                            // TODO: Support third party casting services
                        }
                    }
                    .transition(.fade)
                }
#endif
                ActionButton(actionType: .Queue, enabled: $navigationModal.showQueue) {
                    withAnimation(.interactiveSpring()) {
                        if !self.navigationModal.showQueue {
                            self.navigationModal.showLyrics = false
                        }
                        self.navigationModal.showQueue.toggle()
                    }
                }
                if self.ciderPlayback.nowPlayingState.hasItemToPlay {
                    ActionButton(actionType: .Lyrics, enabled: $navigationModal.showLyrics) {
                        withAnimation(.interactiveSpring()) {
                            if !self.navigationModal.showLyrics {
                                self.navigationModal.showQueue = false
                            }
                            self.navigationModal.showLyrics.toggle()
                        }
                    }
                    .contextMenu(Diagnostic.isDebug ? [
                        ContextMenuArg("Copy Lyrics XML"),
                        ContextMenuArg("Copy Prettified Lyrics XML")
                    ] : [],  { id in
                        Task {
#if os(macOS)
                            if id == "copy-lyrics-xml", let item = self.ciderPlayback.nowPlayingState.item, let lyricsXml = await self.mkModal.AM_API.fetchLyrics(id: item.id) {
                                self.nativeUtilsWrapper.nativeUtils.copy_string_to_clipboard(lyricsXml)
                            }
                            
                            if id == "copy-prettified-lyrics-xml", let item = self.ciderPlayback.nowPlayingState.item, let lyricsXml = await self.mkModal.AM_API.fetchLyrics(id: item.id), let lyricsXML = try? XMLDocument(xmlString: lyricsXml) {
                                self.nativeUtilsWrapper.nativeUtils.copy_string_to_clipboard(lyricsXML.xmlString(options: .nodePrettyPrint))
                            }
#endif
                        }
                    })
                    .transition(.fade)
                }
                Spacer()
                    .frame(width: 10)
            }
            .contentShape(Rectangle())
            .gesture(TapGesture(count: 2).onEnded {
                self.appWindowModal.nsWindow?.zoom(nil)
            })
            
            SearchBar()
        }
        .animation(.spring.speed(2), value: navigationModal.isBackAvailable)
        .animation(.spring.speed(2), value: navigationModal.shouldHideSidebar)
        .frame(height: titleBarHeight)
        .enableInjection()
    }
}

struct AppTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        AppTitleBar()
            .environmentObject(AppWindowModal())
    }
}
