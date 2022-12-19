//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

extension TimeInterval {
    
    var hourMinuteSecondMS: String {
        String(format:"%d:%02d:%02d.%03d", hour, minute, second, millisecond)
    }
    
    var minuteSecondMS: String {
        String(format:"%d:%02d.%03d", minute, second, millisecond)
    }
    
    var minuteSecond: String {
        String(format: "%d:%02d", minute, second)
    }
    
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    
    var totalSeconds: Int {
        Int(self) % 60
    }
    
    var millisecond: Int {
        Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
    
}
