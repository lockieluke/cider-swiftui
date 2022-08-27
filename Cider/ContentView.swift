//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct ContentView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VisualEffectBackground()
                    .opacity(0.98)
                VStack {
                    AppTitleBar(toolbarHeight: geometry.safeAreaInsets.top)
                }
            }
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
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
