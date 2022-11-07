//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class CiderPlayback {
    
    static let shared = CiderPlayback()
    
    private let proc: Process
    private let agentPort: UInt16
    private let agentSessionId: String
    private let commClient: NetworkingProvider
    
    init() {
        let pipe = Pipe()
        pipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if data.isEmpty {
                fileHandle.readabilityHandler = nil
            } else {
                guard let str = String(data: data, encoding: .utf8) else {
                    fileHandle.readabilityHandler = nil
                    return
                }
                print("CiderPlaybackAgent: \(str)")
            }
        }
        let agentSessionId = UUID().uuidString
        let proc = Process()
        let agentPort = NetworkingProvider.findFreeLocalPort()
        guard let execUrl = Bundle.main.sharedSupportURL?.appendingPathComponent("CiderPlaybackAgent") else { fatalError("Error finding CiderPlaybackAgent") }
        proc.arguments = ["--agent-port", String(agentPort), "--agent-session-id", "\"\(agentSessionId)\""]
        proc.executableURL = execUrl
        proc.standardOutput = pipe
        
        self.agentSessionId = agentSessionId
        self.proc = proc
        self.commClient = NetworkingProvider(baseURL: URL(string: "http://127.0.0.1:\(agentPort)")!, defaultHeaders: ["User-Agent": "Cider SwiftUI", "Agent-Session-ID": agentSessionId])
        self.agentPort = agentPort
    }
    
    func setDeveloperToken(developerToken: String) {
        self.proc.arguments?.append(contentsOf: ["--am-token", developerToken])
    }
    
    func setUserToken(userToken: String) {
        self.proc.arguments?.append(contentsOf: ["--am-user-token", userToken])
    }
    
    func start() {
        do {
            try proc.run()
            print("CiderPlaybackAgent on port \(self.agentPort) with Session ID \(self.agentSessionId)")
        } catch {
            fatalError("Error running CiderPlaybackAgent: \(error)")
        }
    }
    
    func shutdown() async {
        do {
            _ = try await self.commClient.request("/shutdown")
        } catch {
            print("Error shutting down CiderPlaybackAgent: \(error)")
        }
    }
    
    func shutdownSync() {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await self.shutdown()
            semaphore.signal()
        }
        semaphore.wait()
    }
    
}
