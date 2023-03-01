//
//  DiscordRPCModal.swift
//  Cider
//
//  Created by Sherlock LUK on 17/02/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

class DiscordRPCModal: ObservableObject {
    
    let agent: DiscordRPCAgent
    
    init() {
        self.agent = DiscordRPCAgent()
    }
    
}
