//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct NavigationContainer: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        ZStack {
            if self.mkModal.isAuthorised {
                ForEach(navigationModal.viewsStack, id: \.id) { viewStack in
                    let isPresent = viewStack.isPresent
                    let currentRootStack = navigationModal.currentRootStack
                    let viewStackOrigin = viewStack.rootStackOrigin ?? .AnyView
                    let shouldUpperStackShow = isPresent && currentRootStack == viewStackOrigin
                    
                    switch viewStack.stackType {
                        
                    case .Home:
                        HomeView()
                            .environmentObject(appWindowModal)
                            .environmentObject(mkModal)
                            .environmentObject(personalisedData)
                            .environmentObject(navigationModal)
                            .environmentObject(ciderPlayback)
                            .hideWithoutDestroying(currentRootStack != .Home)
                        
                    case .Media:
                        DetailedView(detailedViewParams: viewStack.params as! DetailedViewParams)
                            .environmentObject(appWindowModal)
                            .environmentObject(mkModal)
                            .environmentObject(navigationModal)
                            .environmentObject(ciderPlayback)
                            .opacity(shouldUpperStackShow ? 1 : 0)
                            .allowsHitTesting(shouldUpperStackShow)
                        
                    }
                    
                }
            }
        }
        .padding(.top, 40)
        .padding(.bottom, 100)
        .enableInjection()
    }
}

struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer()
    }
}
