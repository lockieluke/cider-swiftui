//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

enum WSTarget: String,  CaseIterable, Identifiable {
    
    case CiderPlaybackAgent, Unknown
    var id: Self { self }
    
}

enum WSTrafficType : String {
    
    case Receive, Send, Bi
    
}

struct WSTrafficRecord {
    
    var target: WSTarget = .Unknown
    let rawJSONString: String
    var json: JSON {
        get {
            guard let data = rawJSONString.data(using: .utf8),
                  let jsonObj = try? JSON(data: data) else { return JSON([]) }
            
            return jsonObj
        }
    }
    let dateSent: Date
    var trafficType: WSTrafficType = .Bi
    let requestId: String
    let identifiableKey: String = UUID().uuidString
    
}

class WSModal: ObservableObject {
    
    static let shared = WSModal()
    
    @Published var traffic: [WSTrafficRecord] = []
    
}
