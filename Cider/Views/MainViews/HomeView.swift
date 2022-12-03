//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import Introspect

struct HomeView: View {
    
    @ObservedObject private var iO = Inject.observer
    @EnvironmentObject private var mkModal: MKModal
    @EnvironmentObject private var appWindowModal: AppWindowModal
    
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    
    var body: some View {
        VStack {
            if mkModal.isAuthorised && self.personalisedData.recommendationSections != nil {
                ScrollView(.vertical) {
                    VStack {
                        ForEach(self.personalisedData.recommendationSections?.musicRecommendations ?? [], id: \.id) { musicRecommendation in
                            MediaShowcaseRow(rowTitle: musicRecommendation.title, recommendationSection: musicRecommendation)
                                .environmentObject(appWindowModal)
                                .environmentObject(ciderPlayback)
                                .environmentObject(navigationModal)
                                .isHidden(navigationModal.isInDetailedView)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .introspectScrollView { scrollView in
                    scrollView.autohidesScrollers = true
                    scrollView.scrollerStyle = .overlay
                }
                .allowsHitTesting(!navigationModal.isInDetailedView)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .task {
            if self.personalisedData.recommendationSections != nil { return }
            
            self.personalisedData.recommendationSections = try? await self.mkModal.AM_API.fetchRecommendations()
        }
        .frame(width: navigationModal.currentRootStack == .Home ? .infinity : .zero, height: navigationModal.currentRootStack == .Home ? .infinity : .zero)
        .enableInjection()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppWindowModal())
            .environmentObject(MKModal(ciderPlayback: CiderPlayback()))
    }
}
