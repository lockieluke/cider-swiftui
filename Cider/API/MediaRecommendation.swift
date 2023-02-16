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
    let recommendations: [MediaDynamic]
    let size: Int
    
    init(data: JSON) {
        self.id = data["id"].stringValue
        self.title = data["attributes"]["title"]["stringForDisplay"].stringValue
        self.type = MediaRecommendationSectionType(rawValue: data["type"].stringValue) ?? .PersonalRecommendation
        
        let recommendationDatas = data["relationships"]["contents"]["data"]
        self.recommendations = recommendationDatas.arrayValue.compactMap { recommendationData in
            let type = MediaType(rawValue: recommendationData["type"].stringValue) ?? .AnyMedia
            if type == .Album {
                return .mediaItem(MediaItem(data: recommendationData))
            } else if type == .Playlist {
                return .mediaPlaylist(MediaPlaylist(data: recommendationData))
            }
            
            return nil
        }
        self.size = recommendationDatas.count
    }
    
}
