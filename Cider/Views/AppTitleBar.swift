//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct AppTitleBar: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var searchModal: SearchModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var toolbarHeight: CGFloat = 0
    
    private var titleBarHeight: CGFloat {
        get {
            return toolbarHeight > 40 ? toolbarHeight : 40
        }
    }
    
    var body: some View {
        ZStack {
            VisualEffectBackground()
                .frame(height: titleBarHeight)
                .overlay {
                    Rectangle().fill(Color("PrimaryColour")).opacity(0.5)
                }
                .gesture(TapGesture(count: 2).onEnded {
                    appWindowModal.nsWindow?.zoom(nil)
                })
            
            SegmentedControl(
                items: [
                    SegmentedControlItemData(title: "Home", icon: .Home),
                    SegmentedControlItemData(title: "Library", icon: .Library)
                ],
                segmentedItemChanged: { currentSegmentedItem in
                    self.navigationModal.currentRootStack = RootNavigationType(rawValue: currentSegmentedItem) ?? .AnyView
                }
            )
            
            HStack(spacing: 0) {
                Spacer()
                    .frame(width: 85)
                Divider()
                    .frame(height: 25)
                    .padding(.trailing, 10)
                
                if navigationModal.navigationActions.enableBack {
                    ActionButton(actionType: .Back) {
                        self.navigationModal.navigationActions.backAction?()
                    }
                }
                
                if navigationModal.navigationActions.enableForward {
                    ActionButton(actionType: .Forward) {
                        self.navigationModal.navigationActions.forwardAction?()
                    }
                }
                
                ActionButton(actionType: .Library)
                Spacer()
            }
            
            SearchBar()
                .environmentObject(searchModal)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
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
