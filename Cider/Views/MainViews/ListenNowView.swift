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
        Group {
            if mkModal.isAuthorised && self.personalisedData.recommendationSections != nil {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(self.personalisedData.recommendationSections?.musicRecommendations ?? [], id: \.id) { musicRecommendation in
                            MediaShowcaseRow(rowTitle: musicRecommendation.title, recommendationSection: musicRecommendation)
                                .environmentObject(ciderPlayback)
                                .environmentObject(navigationModal)
                                .isHidden(navigationModal.currentlyPresentViewType != .Root && navigationModal.currentRootStack != .ListenNow)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .transparentScrollbars()
                .allowsHitTesting(navigationModal.currentlyPresentViewType == .Root && navigationModal.currentRootStack == .ListenNow)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            if self.personalisedData.recommendationSections != nil { return }
            
            self.personalisedData.recommendationSections = try? await self.mkModal.AM_API.fetchRecommendations()
        }
        .enableInjection()
    }
}

struct ListenNowView_Previews: PreviewProvider {
    static var previews: some View {
        ListenNowView()
            .environmentObject(AppWindowModal())
        #if os(macOS)
            .environmentObject(MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal(), discordRPCModal: DiscordRPCModal())))
        #else
            .environmentObject(MKModal(ciderPlayback: CiderPlayback(appWindowModal: AppWindowModal())))
        #endif
    }
}
