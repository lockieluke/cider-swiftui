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
    @EnvironmentObject private var navigationModal: NavigationModal
    
    #if os(macOS)
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    @EnvironmentObject private var discordRPCModal: DiscordRPCModal
    @EnvironmentObject private var authModal: AuthModal
    @EnvironmentObject private var cacheModal: CacheModal
    #endif
    
    @StateObject private var searchModal = SearchModal()
    @StateObject private var personalisedData = PersonalisedData()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                NavigationContainer()
                
                VStack {
                    AppTitleBar()
                    
                    Spacer()
                    PlaybackView()
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
            .background(VisualEffectBackground(material: .fullScreenUI).edgesIgnoringSafeArea(.top))
            .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
            .enableInjection()
        }
        .environmentObject(searchModal)
        .environmentObject(navigationModal)
        .environmentObject(personalisedData)
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
