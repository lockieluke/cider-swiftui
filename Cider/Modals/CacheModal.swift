//
//  CacheModal.swift
//  Cider
//
//  Created by Sherlock LUK on 24/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Cache

class CacheModal: ObservableObject {
    
    @Published var storage: Storage<String, String>?
    
    private let logger = Logger(label: "Caching")
    
    init() {
        let diskConfig = DiskConfig(name: "Cider")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        do {
            self.storage = try Storage<String, String>(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: String.self)
            )
        } catch {
            self.logger.error("Failed to initialise Cache: \(error)")
            self.storage = nil
        }
        
        do {
            try self.storage?.removeExpiredObjects()
        } catch {
            self.logger.error("Failed to remove expired cache objects: \(error)")
        }
    }
    
}
