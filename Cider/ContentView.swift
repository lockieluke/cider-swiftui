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
    @StateObject private var searchModal = SearchModal()
    @StateObject private var navigationModal = NavigationModal()
    @StateObject private var personalisedData = PersonalisedData()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectBackground()
                    .opacity(0.98)
                
                VStack {
                    if self.mkModal.isAuthorised {
                        HomeView()
                            .padding(.top, 40)
                            .padding(.bottom, 100)
                            .environmentObject(appWindowModal)
                            .environmentObject(mkModal)
                            .environmentObject(personalisedData)
                            .environmentObject(navigationModal)
                    }
                }
                
                VStack {
                    AppTitleBar(toolbarHeight: geometry.safeAreaInsets.top, rootPageChanged: { currentRootPage in
                        self.navigationModal.currentRootStack = currentRootPage
                    })
                    .environmentObject(appWindowModal)
                    .environmentObject(searchModal)
                    Spacer()
                    PlaybackView()
                        .environmentObject(appWindowModal)
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
                    CiderPlayback.shared.setUserToken(userToken: userToken)
                    CiderPlayback.shared.start()
                    
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
        ContentView(authWorker: AuthWorker(mkModal: MKModal(), appWindowModal: AppWindowModal()))
    }
}
