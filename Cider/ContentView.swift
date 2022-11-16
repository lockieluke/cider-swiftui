//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    @ObservedObject private var appWindowModal = AppWindowModal.shared
    @ObservedObject private var mkModal = MKModal.shared
    
    @StateObject private var navigationModal = NavigationModal()
    @StateObject private var personalisedData = PersonalisedData()
    
    @State private var authWorkerView: AuthWorker?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectBackground()
                    .opacity(0.98)
                
                VStack {
                    if self.mkModal.isAuthorised {
//                        let homeHidden = Binding<Bool>(get: { self.navigationModal.currentRootStack != .Home }, set: { _ in })
                        HomeView(mkModal: mkModal, appWindowModal: appWindowModal)
                           .padding(.top, 40)
                           .padding(.bottom, 100)
                           .environmentObject(personalisedData)
                           .environmentObject(navigationModal)
                    }
                }
                
                VStack {
                    AppTitleBar(appWindowModal: appWindowModal, toolbarHeight: geometry.safeAreaInsets.top, rootPageChanged: { currentRootPage in
                        self.navigationModal.currentRootStack = currentRootPage
                    })
                    Spacer()
                    PlaybackView(appWindowModal: appWindowModal)
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
            .onAppear {
                Task {
                    _ = await self.mkModal.authorise()
                    
                    self.authWorkerView = AuthWorker()
                    authWorkerView?.presentAuthView() { userToken in
                        mkModal.authenticateWithToken(userToken: userToken)
                        CiderPlayback.shared.setUserToken(userToken: userToken)
                        CiderPlayback.shared.start()
                        
                        Task {
                            await self.mkModal.AM_API.initStorefront()
                        }
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
        ContentView()
    }
}
