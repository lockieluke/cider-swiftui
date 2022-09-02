//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct AMPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var recommendation: AMRecommendation
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: recommendation.artwork.url.replacingOccurrences(of: "{w}", with: "100").replacingOccurrences(of: "{h}", with: "100"))) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            } placeholder: {
                ProgressView()
            }
            Text("\(recommendation.title)")
        }
        .frame(width: 150, height: 150)
        .enableInjection()
    }
}
