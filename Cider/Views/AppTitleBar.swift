//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct AppTitleBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @ObservedObject private var searchModal = SearchModal.shared
    @ObservedObject public var appWindowModal: AppWindowModal
    
    public var toolbarHeight: CGFloat = 0
    
    private var titleBarHeight: CGFloat {
        get {
            return toolbarHeight > 40 ? toolbarHeight : 42
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color("PrimaryColour"))
                    .frame(width: geometry.size.width, height: titleBarHeight)
                
                SegmentedControl(
                    items: ["Home", "Listen Now", "Browse", "Radio"],
                    icons: [.Home, .ListenNow, .Browse, .Radio]
                )
                
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: 85)
                    Divider()
                        .frame(height: 25)
                        .padding(.trailing, 10)
                    if appWindowModal.windowSize.width > 850 {
                        ActionButton(actionType: .Back)
                        ActionButton(actionType: .Forward)
                    }
                    ActionButton(actionType: .Library)
                    Spacer()
                }
                
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: geometry.size.width * 0.8)
                    SearchBar(searchModal: searchModal)
                }
            }
            .frame(minHeight: toolbarHeight)
            .enableInjection()
        }
    }
}

struct AppTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        AppTitleBar(appWindowModal: .shared)
    }
}
