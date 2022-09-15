//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    @ObservedObject private var appWindowModal = AppWindowModal.shared
    @ObservedObject private var mkModal = MKModal.shared
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectBackground()
                    .opacity(0.98)
                HomeView(mkModal: mkModal, appWindowModal: appWindowModal)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                VStack {
                    AppTitleBar(appWindowModal: appWindowModal, toolbarHeight: geometry.safeAreaInsets.top)
                    Spacer()
                    PlaybackView(appWindowModal: appWindowModal)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .frame(height: 100)
                }
                
                if mkModal.hasDeveloperToken {
                    AuthWorkerView(authenticatingCallback: { userToken in
                        mkModal.authenticateWithToken(userToken: userToken)
                    })
                    .frame(width: .zero, height: .zero)
                }
            }
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            .onChange(of: geometry.size) { newSize in
                appWindowModal.windowSize = newSize
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
