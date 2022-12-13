//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

enum AMNetworkingError : Error {
    
    case unableToFetchRecommendations(String),
    unableToFetchTracks(String)
    
}

extension AMNetworkingError : CustomStringConvertible {
    var description: String {
        switch self {
        case .unableToFetchRecommendations:
            return "Unable to fetch recommendations"
            
        case .unableToFetchTracks:
            return "Unable to fetch tracks"
        }
    }
}

extension AMNetworkingError : LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .unableToFetchRecommendations:
            return NSLocalizedString("Unable to fetch recommendations", comment: "Error fetching recommendations")
            
        default:
            return nil
        }
    }
    
}

enum AMAuthError : Error {
    
case invalidDeveloperToken,
    invalidUserToken
    
}
