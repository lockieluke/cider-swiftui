//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import SwiftUI
import Inject

struct ListenNowView: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                Text("Listen Now")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                ForEach(self.personalisedData.recommendationSections?.musicRecommendations ?? [], id: \.id) { musicRecommendation in
                    MediaShowcaseRow(rowTitle: musicRecommendation.title, items: musicRecommendation.recommendations)
                        .isHidden(navigationModal.currentlyPresentViewType != .Root && navigationModal.currentRootStack != .ListenNow)
                }
            }
        }
        .transparentScrollbars()
        .task {
            if self.personalisedData.recommendationSections != nil { return }
            
            self.personalisedData.recommendationSections = await self.mkModal.AM_API.fetchRecommendations()
        }
        .enableInjection()
    }
}

struct ListenNowView_Previews: PreviewProvider {
    static var previews: some View {
        ListenNowView()
            .environmentObject(AppWindowModal())
#if os(macOS)
//            .environmentObject(MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal()), cacheModal: CacheModal()))
#else
//            .environmentObject(MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal())))
#endif
    }
}
