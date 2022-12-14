//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    var authWorker: AuthWorker
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var prefModal: PrefModal
    
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
                
                VStack {
                    AppTitleBar(toolbarHeight: geometry.safeAreaInsets.top)
                    .environmentObject(appWindowModal)
                    .environmentObject(searchModal)
                    .environmentObject(navigationModal)
                    
                    Spacer()
                    PlaybackView()
                        .environmentObject(appWindowModal)
                        .environmentObject(ciderPlayback)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .frame(height: 100)
                }
            }
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .onChange(of: geometry.size) { newSize in
                appWindowModal.windowSize = newSize
            }
            .task {
                await self.authWorker.presentAuthView() { userToken in
                    self.mkModal.authenticateWithToken(userToken: userToken)
                    self.ciderPlayback.setUserToken(userToken: userToken)
                    self.ciderPlayback.start()
                    
                    Task {
                        await self.mkModal.AM_API.initStorefront()
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
        ContentView(authWorker: AuthWorker(mkModal: MKModal(ciderPlayback: CiderPlayback(prefModal: PrefModal())), appWindowModal: AppWindowModal()))
    }
}
