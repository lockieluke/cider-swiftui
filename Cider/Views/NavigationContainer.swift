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
                HomeView()
                    .environmentObject(appWindowModal)
                    .environmentObject(mkModal)
                    .environmentObject(personalisedData)
                    .environmentObject(navigationModal)
                    .environmentObject(ciderPlayback)
                
                if navigationModal.isInDetailedView {
                    DetailedView()
                        .environmentObject(appWindowModal)
                        .environmentObject(navigationModal)
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
