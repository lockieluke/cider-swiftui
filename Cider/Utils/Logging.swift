//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Darwin
import RainbowSwift

class Logger {
    
    static let shared = Logger(label: "Shared")
    private let label: String
    
    init(label: String) {
        self.label = label
    }
    
    func info(_ message: String) {
        fputs("[\(self.getTimestampInString())] \("[\(self.label)]".bold) \(message)\n", stdout)
    }
    
    func success(_ message: String, displayTick: Bool = false) {
        fputs("[\(self.getTimestampInString())] \("[\(self.label)]".bold) \(message.green)\(displayTick ? " ✔" : "")\n", stdout)
    }
    
    func error(_ message: String, displayCross: Bool = false) {
        fputs("[\(self.getTimestampInString())] \("[\(self.label)]".bold) \("ERROR".red) \(message)\(displayCross ? " ✗" : "")\n", stderr)
    }
    
    private func getTimestampInString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(TimeZone.current.identifier.italic) \(dateFormatter.string(from: date))"
    }
    
}
