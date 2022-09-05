//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct AMPresentable: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public var recommendation: AMRecommendation
    private let PRESENTABLE_IMG_SIZE = CGSize(width: 200, height: 200)
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: recommendation.artwork.url.replacingOccurrences(of: "{w}", with: "200").replacingOccurrences(of: "{h}", with: "200"))) { image in
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: PRESENTABLE_IMG_SIZE.width, height: PRESENTABLE_IMG_SIZE.height)
            } placeholder: {
                ProgressView()
            }
            Text("\(recommendation.title)")
        }
        .frame(width: PRESENTABLE_IMG_SIZE.width + 50, height: PRESENTABLE_IMG_SIZE.height + 50)
        .enableInjection()
    }
}
