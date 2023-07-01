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
    var authWorker: AuthWorker
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
                #if os(macOS)
                    .environmentObject(nativeUtilsWrapper)
                #endif
                
                VStack {
                    AppTitleBar(toolbarHeight: geometry.safeAreaInsets.top)
                    .environmentObject(appWindowModal)
                    .environmentObject(searchModal)
                    .environmentObject(navigationModal)
                    .environmentObject(ciderPlayback)
                    
                    Spacer()
                    PlaybackView()
                        .environmentObject(appWindowModal)
                        .environmentObject(ciderPlayback)
                        .environmentObject(navigationModal)
                        .environmentObject(mkModal)
                    #if os(macOS)
                        .environmentObject(nativeUtilsWrapper)
                    #endif
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .frame(height: 100)
                }
            }
            .onTapGesture {
                #if canImport(AppKit)
                NSApp.keyWindow?.makeFirstResponder(nil)
                #endif
            }
            .task {
                #if os(macOS)
                await self.authWorker.presentAuthView() { userToken in
                    self.discordRPCModal.agent.start()
                    self.mkModal.authenticateWithToken(userToken: userToken)
                    self.ciderPlayback.setUserToken(userToken: userToken)
                    self.ciderPlayback.start()
                    
                    Task {
                        await self.mkModal.AM_API.initStorefront()
                        self.navigationModal.appendViewStack(NavigationStack(isPresent: true, params: .homeViewParams))
                    }
                }
                #endif
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
        ContentView(authWorker: AuthWorker(mkModal: MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal(), discordRPCModal: DiscordRPCModal())), appWindowModal: AppWindowModal()))
        #elseif os(iOS)
        ContentView()
        #endif
    }
}
