//
//  SearchSuggestion.swift
//  Cider
//
//  Created by Sherlock LUK on 10/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON

struct SearchSuggestions {
    
    struct SearchTerm {
        
        let searchTerm: String
        let displayTerm: String
        
    }
    
    enum SearchTopResult {
        case track(MediaTrack), artist(MediaArtist)
    }
    
    struct SearchSuggestion {
        
        let id: String
        let searchTerm: SearchTerm?
        let searchTopResult: SearchTopResult?
        
        init(id: String, searchTerm: SearchTerm? = nil, searchTopResult: SearchTopResult? = nil) {
            self.id = id
            self.searchTerm = searchTerm
            self.searchTopResult = searchTopResult
        }
        
    }
    
    var searchSuggestions: [SearchSuggestion]
    
    init(data: JSON) {
        let suggestions = data["suggestions"]
        self.searchSuggestions = suggestions.arrayValue.compactMap { suggestion in
            let suggestionType = suggestion["kind"].string
            if suggestionType == "terms" {
                return SearchSuggestion(id: UUID().uuidString, searchTerm: SearchTerm(searchTerm: suggestion["searchTerm"].stringValue, displayTerm: suggestion["displayTerm"].stringValue))
            } else if suggestionType == "topResults" {
                let content = suggestion["content"]
                let type = MediaType(rawValue: content["type"].stringValue)
                if type == .Artist {
                    return SearchSuggestion(id: content["id"].stringValue, searchTopResult: .artist(MediaArtist(data: content)))
                } else if type == .Song {
                    return SearchSuggestion(id: content["id"].stringValue, searchTopResult: .track(MediaTrack(data: content)))
                }
            }
            
            return nil
        }
    }
    
}
