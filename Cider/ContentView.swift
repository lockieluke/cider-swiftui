//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Throttler
import InjectHotReload

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var discordRPCModal: DiscordRPCModal
    @EnvironmentObject private var nativeUtilsWrapper: NativeUtilsWrapper
    
    var authWorker: AuthWorker
    
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
                    .environmentObject(nativeUtilsWrapper)
                
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
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .frame(height: 100)
                }
            }
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .task {
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
            }
            .frame(width: geometry.size.width, height: geometry.size.height + geometry.safeAreaInsets.top)
            .edgesIgnoringSafeArea(.top)
            .enableInjection()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(authWorker: AuthWorker(mkModal: MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal(), discordRPCModal: DiscordRPCModal())), appWindowModal: AppWindowModal()))
    }
}
