//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import InjectHotReload
import Introspect

struct MediaShowcaseRow: View {
    
    @ObservedObject private var iO = Inject.observer
    
    @EnvironmentObject private var appWindowModal: AppWindowModal
    @EnvironmentObject private var ciderPlayback: CiderPlayback
    @EnvironmentObject private var navigationModal: NavigationModal
    
    var rowTitle: String?
    var recommendationSection: MusicRecommendationSection?
    
    var body: some View {
        PatchedGeometryReader { geometry in
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
                                MediaPresentable(item: .mediaItem(recommendation), maxRelative: max(geometry.size.width, geometry.size.height))
                                    .environmentObject(appWindowModal)
                                    .environmentObject(ciderPlayback)
                                    .environmentObject(navigationModal)
                                    .padding()
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
        }
        .enableInjection()
    }
}

struct RecommendationSection_Previews: PreviewProvider {
    static var previews: some View {
        MediaShowcaseRow()
    }
}
