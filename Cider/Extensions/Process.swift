//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

#if os(macOS)
extension Process {
    
    static func sysctlByName(name: String) -> String {
        return Process.stringFromTerminal(command: "sysctl -n \(name)")
    }
    
    static func stringFromTerminal(command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launchPath = "/bin/zsh"
        task.arguments = ["-c", command]
        task.launch()
        
        let str = String(data: pipe.fileHandleForReading.availableData, encoding: .utf8) ?? ""
        
        var newStr = str
        if let last = newStr.last {
            if last.isNewline {
                newStr.removeLast()
            }
        }
        
        return newStr
    }
    
    static let processor = sysctlByName(name: "machdep.cpu.brand_string")
    static let cores = sysctlByName(name: "machdep.cpu.core_count")
    static let threads = sysctlByName(name: "machdep.cpu.thread_count")
    static let vendor = sysctlByName(name: "machdep.cpu.vendor")
    static let family = sysctlByName(name: "machdep.cpu.family")
}
#endif
