//
//  HTTPURLResponse.swift
//  Cider
//
//  Created by Sherlock LUK on 06/01/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    
    var ok: Bool {
        return (200...299).contains(self.statusCode)
    }
    
}
