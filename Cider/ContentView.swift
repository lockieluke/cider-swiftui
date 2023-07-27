//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Throttler
import Inject

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    #if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    @EnvironmentObject private var discordRPCModal: DiscordRPCModal
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var cacheModal: CacheModal
    #endif
    
    @StateObject private var searchModal = SearchModal()
    @StateObject private var navigationModal = NavigationModal()
    @StateObject private var personalisedData = PersonalisedData()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectBackground()
                    .opacity(0.98)
                
                NavigationContainer()
                    .environmentObject(appWindowModal)
                    .environmentObject(mkModal)
                    .environmentObject(personalisedData)
                    .environmentObject(navigationModal)
                    .environmentObject(ciderPlayback)
                    .environmentObject(searchModal)
                    .environmentObject(cacheModal)
                #if os(macOS)
                    .environmentObject(nativeUtilsWrapper)
                #endif
                
                VStack {
                    AppTitleBar()
                    .environmentObject(appWindowModal)
                    .environmentObject(searchModal)
                    .environmentObject(navigationModal)
                    .environmentObject(ciderPlayback)
                    .environmentObject(mkModal)
                #if os(macOS)
                    .environmentObject(nativeUtilsWrapper)
                #endif
                    
                    Spacer()
                    PlaybackView()
                        .environmentObject(appWindowModal)
                        .environmentObject(ciderPlayback)
                        .environmentObject(navigationModal)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .frame(height: 100)
                }
            }
            .onTapGesture {
                #if canImport(AppKit)
                NSApp.keyWindow?.makeFirstResponder(nil)
                #endif
            }
            .onAppear {
                self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .rootViewParams))
            }
            .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
            .enableInjection()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        #if os(macOS)
        ContentView()
            .environmentObject(AuthModal(mkModal: MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal(), discordRPCModal: DiscordRPCModal()), cacheModal: CacheModal()), appWindowModal: AppWindowModal(), cacheModel: CacheModal()))
        #elseif os(iOS)
        ContentView()
        #endif
    }
}
