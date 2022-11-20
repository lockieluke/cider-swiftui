//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload

struct MediaShowcaseRow: View {
    
    @ObservedObject private var iO = Inject.observer
    
    private let rowTitle: String?
    private let recommendationSection: MusicRecommendationSection?
    
    init(_ rowHeading: String? = nil, recommendationSection: MusicRecommendationSection? = nil) {
        self.rowTitle = rowHeading
        self.recommendationSection = recommendationSection
    }
    
    var body: some View {
        VStack {
            Text(rowTitle ?? "No Title")
                .font(.system(size: 15).bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.top, 10)
            ScrollView([.horizontal]) {
                LazyHStack {
                    if let recommendations = recommendationSection?.recommendations {
                        ForEach(recommendations, id: \.title) { recommendation in
                            RecommendationItemPresentable(recommendation: recommendation)
                        }
                    }
                }
                .introspectScrollView { scrollView in
                    scrollView.autohidesScrollers = true
                    scrollView.scrollerStyle = .overlay
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .enableInjection()
    }
}

struct RecommendationSection_Previews: PreviewProvider {
    static var previews: some View {
        MediaShowcaseRow()
    }
}
