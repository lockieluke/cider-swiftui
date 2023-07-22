//
//  Calendar.swift
//  Cider
//
//  Created by Sherlock LUK on 15/07/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

class DateUtils {
    
    static var timeOfDayInWords: String {
        get {
            let hour = Calendar.current.component(.hour, from: Date())

            switch hour {
            case 6..<12 : return "Morning"
            case 12..<17 : return "Afternoon"
            case 17..<22 : return "Evening"
            default: return "Night"
            }
        }
    }
    
    static func formatTimezoneOffset(date: Date = Date()) -> String {
        func leadingZeros(_ number: Int, _ size: Int = 2) -> String {
            var numString = String(number)
            while numString.count < size {
                numString = "0" + numString
            }
            return numString
        }

        let timeZoneOffsetMinutes = TimeZone.current.secondsFromGMT() / 60
        let hours = abs(timeZoneOffsetMinutes) / 60
        let minutes = abs(timeZoneOffsetMinutes) % 60

        var sign = "+"
        if timeZoneOffsetMinutes != 0 {
            sign = timeZoneOffsetMinutes > 0 ? "-" : "+"
        }

        return "\(sign)\(leadingZeros(hours, 2)):\(leadingZeros(minutes, 2))"
    }
    
}
