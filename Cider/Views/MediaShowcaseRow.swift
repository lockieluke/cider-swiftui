//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject
import Introspect

struct MediaShowcaseRow: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var rowTitle: String?
    var recommendationSection: MediaRecommendationSection?
    
    var body: some View {
        if let recommendations = recommendationSection?.recommendations, !recommendations.isEmpty, let rowTitle = rowTitle {
            PatchedGeometryReader { geometry in
                VStack {
                    Text(rowTitle)
                        .font(.system(size: 15).bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 15)
                        .padding(.top, 10)
                    ScrollView([.horizontal]) {
                        LazyHStack {
                            ForEach(recommendations, id: \.self) { recommendation in
                                MediaPresentable(item: recommendation, maxRelative: geometry.maxRelative.clamped(to: 1000...1300), geometryMatched: true)
                                    .environmentObject(ciderPlayback)
                                    .environmentObject(navigationModal)
                                    .padding()
                            }
                        }
                        .transparentScrollbars()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .enableInjection()
        }
    }
}

struct RecommendationSection_Previews: PreviewProvider {
    static var previews: some View {
        MediaShowcaseRow()
    }
}
