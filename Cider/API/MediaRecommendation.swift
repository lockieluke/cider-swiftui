//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

enum MediaRecommendationSectionType : String {
    
    case PersonalRecommendation = "personal-recommendation"
    
}

struct MediaRecommendationSections {
    
    let size: Int
    let musicRecommendations: [MediaRecommendationSection]
    
    init(datas: JSON) {
        self.musicRecommendations = datas["data"].arrayValue.map { data in
            return MediaRecommendationSection(data: data)
        }
        self.size = datas.count
    }
    
}

struct MediaRecommendationSection {
    
    let id: String
    let title: String
    let type: MediaRecommendationSectionType
    let recommendations: [MediaItem]
    let size: Int
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.title = data["attributes"]["title"]["stringForDisplay"].stringValue
        self.type = MediaRecommendationSectionType(rawValue: data["type"].stringValue) ?? .PersonalRecommendation
        
        let recommendationDatas = data["relationships"]["contents"]["data"]
        self.recommendations = recommendationDatas.arrayValue.map { recommendationData in
            return MediaItem(data: recommendationData)
        }
        self.size = recommendationDatas.count
    }
    
}
