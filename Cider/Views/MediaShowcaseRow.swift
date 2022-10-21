//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct MediaShowcaseRow: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public let rowTitle: String?
    public let mediaItems: [AMMediaItem]
    
    init(_ rowHeading: String? = nil, mediaItems: [AMMediaItem] = []) {
        self.rowTitle = rowHeading
        self.mediaItems = mediaItems
    }
    
    var body: some View {
        VStack {
            Text(rowTitle ?? "No Title")
                .font(.system(size: 15).bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 25)
            ScrollView([.horizontal]) {
                HStack {
                    ForEach(self.mediaItems, id: \.title) { mediaItem in
                        AMPresentable(recommendation: mediaItem)
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
