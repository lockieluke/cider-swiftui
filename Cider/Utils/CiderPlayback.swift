//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Starscream

class CiderPlayback : WebSocketDelegate {
    
    static let shared = CiderPlayback()
    
    private let proc: Process
    private let agentPort: UInt16
    private let agentSessionId: String
    private let wsCommClient: CiderWSProvider
    private let commClient: NetworkingProvider
    private var isRunning: Bool
    
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
                var newStr = str
                if let last = newStr.last {
                    if last.isNewline {
                        newStr.removeLast()
                    }
                }
                print("CiderPlaybackAgent: \(newStr)")
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
        self.wsCommClient = CiderWSProvider(baseURL: URL(string: "ws://localhost:\(agentPort)/ws")!, defaultHeaders:  [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        self.commClient = NetworkingProvider(baseURL: URL(string: "http://127.0.0.1:\(agentPort)")!, defaultHeaders: [
            "Agent-Session-ID": agentSessionId,
            "User-Agent": "Cider SwiftUI"
        ])
        self.agentPort = agentPort
        self.isRunning = false
    }
    
    func setDeveloperToken(developerToken: String) {
        if !self.isRunning {
            self.proc.arguments?.append(contentsOf: ["--am-token", developerToken])
        }
    }
    
    func setUserToken(userToken: String) {
        if !self.isRunning {
            self.proc.arguments?.append(contentsOf: ["--am-user-token", userToken])
        }
    }
    
    func setQueue(album: String) async {
        await self.setQueue(requestBody: ["album-id": album])
    }
    
    func setQueue(playlist: String) async {
        await self.setQueue(requestBody: ["playlist-id": playlist])
    }
    
    func setQueue(requestBody: [String : Any]? = nil) async {
        do {
            _ = try await self.wsCommClient.request("/set-queue", body: requestBody)
        } catch {
            print("Set Queue failed \(error)")
        }
    }
    
    func play() async {
        do {
            _ = try await self.wsCommClient.request("/play")
        } catch {
            print("Play failed \(error)")
        }
    }
    
    func start() {
        if self.isRunning {
            return
        }
        
        do {
            try proc.run()
            self.isRunning = true
            print("CiderPlaybackAgent on port \(self.agentPort) with Session ID \(self.agentSessionId)")
            self.wsCommClient.delegate = self
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
                self.wsCommClient.connect()
            }
        } catch {
            print("Error running CiderPlaybackAgent: \(error)")
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
    
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            
        case .connected:
            print("Connected to CiderPlaybackAgent")
            break
            
        case .error(let error):
            guard let error = error else { return }
            print("WebSockets error: \(error)")
            break
            
        default:
            break
            
        }
    }
    
}
