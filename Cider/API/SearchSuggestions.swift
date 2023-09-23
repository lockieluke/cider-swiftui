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
        case track(MediaTrack), artist(MediaArtist), album(MediaItem)
    }
    
    struct Suggestion {
        let id: String
        let searchTerm: SearchTerm?
        let searchTopResult: SearchTopResult?
        
        init(id: String, searchTerm: SearchTerm? = nil, searchTopResult: SearchTopResult? = nil) {
            self.id = id
            self.searchTerm = searchTerm
            self.searchTopResult = searchTopResult
        }
    }
    
    var suggestions: [Suggestion]
    
    init(data: JSON) {
        let suggestionsJSON = data["suggestions"]
        self.suggestions = suggestionsJSON.arrayValue.compactMap { suggestionJSON in
            guard let suggestionType = suggestionJSON["kind"].string else { return nil }
            switch suggestionType {
            case "terms":
                let searchTerm = SearchTerm(searchTerm: suggestionJSON["searchTerm"].stringValue,
                                            displayTerm: suggestionJSON["displayTerm"].stringValue)
                return Suggestion(id: UUID().uuidString, searchTerm: searchTerm)
            case "topResults":
                let content = suggestionJSON["content"]
                guard let type = MediaType(rawValue: content["type"].stringValue) else { return nil }
                switch type {
                case .Artist:
                    return Suggestion(id: content["id"].stringValue, searchTopResult: .artist(MediaArtist(data: content)))
                case .Song:
                    return Suggestion(id: content["id"].stringValue, searchTopResult: .track(MediaTrack(data: content)))
                case .Album:
                    return Suggestion(id: content["id"].stringValue, searchTopResult: .album(MediaItem(data: content)))
                default:
                    return nil
                }
            default:
                return nil
            }
        }
    }
    
}
