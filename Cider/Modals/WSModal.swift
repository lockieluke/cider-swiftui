//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

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
    let dateSent: Date
    var trafficType: WSTrafficType = .Bi
    let id: String
    
    
}

class WSModal: ObservableObject {
    
    static let shared = WSModal()
    
    @Published var traffic: [WSTrafficRecord] = []
    
}
