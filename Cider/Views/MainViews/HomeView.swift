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
    
    @Binding var isHidden: Bool
    
    @State private var recommendationSections: MusicRecommendationSections?
    
    var body: some View {
        VStack {
            if mkModal.isAuthorised && recommendationSections != nil {
                ScrollView([.vertical]) {
                    VStack {
                        ForEach(self.recommendationSections?.musicRecommendations ?? [], id: \.id) { musicRecommendation in
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
            Task {
                await self.mkModal.AM_API.initStorefront()
                do {
                    self.recommendationSections = try await self.mkModal.AM_API.fetchRecommendations()
                } catch AMNetworkingError.unableToFetchRecommendations(let errorMessage) {
                    fatalError("\(errorMessage)")
                }
            }
        }
        .frame(width: isHidden ? .zero : .infinity, height: isHidden ? .zero : .infinity)
        .enableInjection()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(mkModal: .shared, appWindowModal: .shared, isHidden: .constant(false))
    }
}
