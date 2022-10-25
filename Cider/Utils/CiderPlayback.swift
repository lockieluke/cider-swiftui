//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class CiderPlayback {
    
    init() {
        let proc = Process()
        guard let execUrl = Bundle.main.sharedSupportURL?.appendingPathComponent("CiderPlaybackAgent") else { fatalError("Error finding CiderPlaybackAgent") }
        proc.executableURL = execUrl
        do {
            try proc.run()
            print("Successfully launched CiderPlaybackAgent")
        } catch {
            print("Error running CiderPlaybackAgent: \(error)")
        }
    }
    
}
