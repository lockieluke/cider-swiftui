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
    
    @State private var recommendations: AMRecommendations?
    
    var body: some View {
        VStack {
            if mkModal.isAuthorised && recommendations != nil {
                ScrollView([.vertical]) {
                    ForEach(recommendations?.contents ?? [], id: \.id) { content in
                        MediaShowcaseRow(content.title, mediaItems: content.recommendations)
                            .frame(width: appWindowModal.windowSize.width)
                    }
                    .introspectScrollView { scrollView in
                        scrollView.autohidesScrollers = true
                        scrollView.scrollerStyle = .overlay
                    }
                }
                .frame(maxWidth: appWindowModal.windowSize.width)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            mkModal.authorise()
        }
        .onReceive(mkModal.$isAuthorised) { isAuthorised in
            if isAuthorised {
                Task {
                    await mkModal.AM_API.initStorefront()
                    do {
                        self.recommendations = try await mkModal.AM_API.fetchRecommendations()
                    } catch AMNetworkingError.unableToFetchRecommendations(let errorMessage) {
                        fatalError("\(errorMessage)")
                    }
                }
            }
        }
        .enableInjection()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(mkModal: .shared, appWindowModal: .shared)
    }
}
