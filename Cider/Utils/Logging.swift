//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Darwin
import Rainbow

enum SharedLoggers {
    case UIInteraction, DiscordRPC, Authentication
}

class Logger {
    
    static let sharedLoggers: Dictionary<SharedLoggers, Logger> = [
        .UIInteraction: Logger(label: "UIInteraction"),
        .DiscordRPC: Logger(label: "DiscordRPC")
    ]
    static let shared = Logger(label: "Shared")
    private let label: String
    
    init(label: String) {
        self.label = label
    }
    
    func info(_ message: String) {
        let time = self.getTimestampInString()
        #if os(macOS) && DEBUG
        DispatchQueue.main.async {
            addLogEntry(time, "info", message)
        }
        #endif
        fputs("[\(time)] \("[\(self.label)]".bold) \(message)\n", stdout)
    }
    
    func success(_ message: String, displayTick: Bool = false) {
        let time = self.getTimestampInString()
        #if os(macOS) && DEBUG
        DispatchQueue.main.async {
            addLogEntry(time, "success", message)
        }
        #endif
        fputs("[\(time)] \("[\(self.label)]".bold) \(message.green)\(displayTick ? " ✔" : "")\n", stdout)
    }
    
    func error(_ message: String, displayCross: Bool = false) {
        fputs("\(self.errorMessage(message, displayCross: displayCross))\n", stderr)
    }
    
    func crashError(_ message: String, displayCross: Bool = false) -> Never {
        return fatalError(self.errorMessage(message, displayCross: displayCross))
    }
    
    private func errorMessage(_ message: String, displayCross: Bool = false) -> String {
        let time = self.getTimestampInString()
        #if os(macOS) && DEBUG
        DispatchQueue.main.async {
            addLogEntry(time, "error", message)
        }
        #endif
        return "[\(time)] \("[\(self.label)]".bold) \("ERROR".red) \(message)\(displayCross ? " ✗" : "")"
    }
    
    private func getTimestampInString() -> String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return "\(TimeZone.current.identifier.italic) \(dateFormatter.string(from: date))"
    }
    
}
