//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct AppTitleBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    var toolbarHeight: CGFloat = 0
    var rootPageChanged: ((_ currentPage: RootNavigationType) -> Void)? = nil
    
    private var titleBarHeight: CGFloat {
        get {
            return toolbarHeight > 40 ? toolbarHeight : 40
        }
    }
    
    var body: some View {
        ZStack {
            VisualEffectBackground()
                .frame(width: appWindowModal.windowSize.width, height: titleBarHeight)
                .overlay {
                    Rectangle().fill(Color("PrimaryColour")).opacity(0.5)
                }
            
            SegmentedControl(
                items: ["Home", "Library"],
                icons: [.Home, .Library],
                segmentedItemChanged: { currentSegmentedItem in
                    self.rootPageChanged?(RootNavigationType(rawValue: currentSegmentedItem) ?? .AnyView)
                }
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
                    .frame(width: appWindowModal.windowSize.width * 0.8)
                SearchBar()
                    .environmentObject(searchModal)
            }
        }
        .frame(height: 40)
        .enableInjection()
    }
}

struct AppTitleBar_Previews: PreviewProvider {
    static var previews: some View {
        AppTitleBar()
            .environmentObject(AppWindowModal())
    }
}
