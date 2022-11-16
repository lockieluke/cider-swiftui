//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject
import Introspect

struct HomeView: View {
    
    @ObservedObject private var iO = Inject.observer
    @ObservedObject public var mkModal: MKModal
    @ObservedObject public var appWindowModal: AppWindowModal
    
    @EnvironmentObject private var personalisedData: PersonalisedData
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var body: some View {
        VStack {
            if mkModal.isAuthorised && self.personalisedData.recommendationSections != nil {
                ScrollView([.vertical]) {
                    VStack {
                        ForEach(self.personalisedData.recommendationSections?.musicRecommendations ?? [], id: \.id) { musicRecommendation in
                            MediaShowcaseRow(musicRecommendation.title, recommendationSection: musicRecommendation)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .introspectScrollView { scrollView in
                    scrollView.autohidesScrollers = true
                    scrollView.scrollerStyle = .overlay
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            if self.personalisedData.recommendationSections != nil { return }
            
            Task {
                do {
                    self.personalisedData.recommendationSections = try await self.mkModal.AM_API.fetchRecommendations()
                } catch AMNetworkingError.unableToFetchRecommendations(let errorMessage) {
                    fatalError("\(errorMessage)")
                }
            }
        }
        .frame(width: navigationModal.currentRootStack == .Home ? .infinity : .zero, height: navigationModal.currentRootStack == .Home ? .infinity : .zero)
        .enableInjection()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(mkModal: .shared, appWindowModal: .shared)
    }
}
