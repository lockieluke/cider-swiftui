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
        VStack {
            if self.mkModal.isAuthorised {
                HomeView()
                    .padding(.top, 40)
                    .padding(.bottom, 100)
                    .environmentObject(appWindowModal)
                    .environmentObject(mkModal)
                    .environmentObject(personalisedData)
                    .environmentObject(navigationModal)
                    .environmentObject(ciderPlayback)
            }
        }
        .enableInjection()
    }
}

struct NavigationContainer_Previews: PreviewProvider {
    static var previews: some View {
        NavigationContainer()
    }
}
