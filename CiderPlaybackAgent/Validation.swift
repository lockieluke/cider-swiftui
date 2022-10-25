//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Swifter

func isReqFromCider(_ headers: [String : String]) -> Bool {
    return (headers[caseInsensitive: "User-Agent"] == "Cider SwiftUI")
}
