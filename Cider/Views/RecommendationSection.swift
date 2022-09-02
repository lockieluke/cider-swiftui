//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import SwiftUI
import Inject

struct RecommendationSection: View {
    
    @ObservedObject private var iO = Inject.observer
    
    public let recommendationTitle: String?
    public let recommendations: [AMRecommendation]
    
    init(_ recommendationTitle: String? = nil, recommendations: [AMRecommendation] = []) {
        self.recommendationTitle = recommendationTitle
        self.recommendations = recommendations
    }
    
    var body: some View {
        VStack {
            Text(recommendationTitle ?? "No Title")
                .font(.system(size: 15).bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack() {
                ForEach(self.recommendations, id: \.title) { recommendation in
                    AMPresentable(recommendation: recommendation)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .enableInjection()
    }
}

struct RecommendationSection_Previews: PreviewProvider {
    static var previews: some View {
        RecommendationSection()
    }
}
