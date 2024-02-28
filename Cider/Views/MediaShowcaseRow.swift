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
    
    @Namespace private var mediaAnimationNamespace
    
    var rowTitle: String
    var items: [MediaDynamic]
    
    var body: some View {
        VStack(spacing: 0) {
            Text(rowTitle)
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
        
            PatchedGeometryReader { geometry in
                ScrollView([.horizontal]) {
                    LazyHStack {
                        ForEach(items, id: \.id) { item in
                            MediaPresentable(item: item, maxRelative: geometry.maxRelative.clamped(to: 1000...1300), animationNamespace: mediaAnimationNamespace)
                                .padding()
                        }
                    }
                }
                .transparentScrollbars()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical)
        .enableInjection()
    }
}

struct RecommendationSection_Previews: PreviewProvider {
    static var previews: some View {
        MediaShowcaseRow(rowTitle: "", items: [])
    }
}
