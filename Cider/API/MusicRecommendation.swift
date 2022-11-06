//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

enum MusicRecommendationSectionType : String {
    
    case PersonalRecommendation = "personal-recommendation"
    
}

struct MusicRecommendationSections {
    
    let size: Int
    let musicRecommendations: [MusicRecommendationSection]
    
    init(datas: JSON) {
        self.musicRecommendations = datas["data"].arrayValue.map { data in
            return MusicRecommendationSection(data: data)
        }
        self.size = datas.count
    }
    
}

struct MusicRecommendationSection {
    
    let id: String
    let title: String
    let type: MusicRecommendationSectionType
    let recommendations: [MusicItem]
    let size: Int
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.title = data["attributes"]["title"]["stringForDisplay"].stringValue
        self.type = MusicRecommendationSectionType(rawValue: data["type"].stringValue) ?? .PersonalRecommendation
        
        let recommendationDatas = data["relationships"]["contents"]["data"]
        self.recommendations = recommendationDatas.arrayValue.map { recommendationData in
            return MusicItem(data: recommendationData)
        }
        self.size = recommendationDatas.count
    }
    
}
