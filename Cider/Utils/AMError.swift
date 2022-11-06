//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

enum AMNetworkingError : Error {
    
    case unableToFetchRecommendations(String)
    
}

extension AMNetworkingError : CustomStringConvertible {
    var description: String {
        switch self {
        case .unableToFetchRecommendations:
            return "Unable to fetch recommendations"
        }
    }
}

extension AMNetworkingError : LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .unableToFetchRecommendations:
            return NSLocalizedString("Unable to fetch recommendations", comment: "Error fetching recommendations")
        }
    }
    
}

enum AMAuthError : Error {
    
case invalidDeveloperToken,
    invalidUserToken
    
}
