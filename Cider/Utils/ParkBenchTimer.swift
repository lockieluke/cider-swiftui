//
//  ParkBenchTimer.swift
//  Cider
//
//  Created by Sherlock LUK on 23/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

class ParkBenchTimer {
    let startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?

    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }

    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()

        return duration!
    }

    var duration: CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}
