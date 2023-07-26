//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import MusicKit
import StoreKit

class MKModal : ObservableObject {
    
    @Published var isAuthorised = false
    @Published var amAuthError: Error?
    @Published var hasDeveloperToken = false
    
    private let logger = Logger(label: "MusicKit Wrapper")
    private let ciderPlayback: CiderPlayback
    
    let AM_API = AMAPI()
    
    init(ciderPlayback: CiderPlayback) {
        self.ciderPlayback = ciderPlayback
    }
    
    func fetchDeveloperToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
//            self.AM_API.requestSKAuthorisation { skStatus in
//                if skStatus != .authorized {
//                    self.resetAuthorisation()
//                }
//            }
            
            Task {
                do {
                    let developerToken = try await self.AM_API.fetchMKDeveloperToken()
//                        let mkAuthStatus = await self.AM_API.requestMKAuthorisation()
//                        if mkAuthStatus != .authorized {
//                            continuation.resume(throwing: NSError(domain: "Failed to request native MusicKit permissions", code: 0))
//                        }
                    DispatchQueue.main.async {
                        self.hasDeveloperToken = true
                        self.ciderPlayback.setDeveloperToken(developerToken: developerToken, mkModal: self)
                        self.logger.success("Successfully fetched MusicKit Developer Token", displayTick: true)
                        continuation.resume(returning: developerToken)
                    }
                } catch {
                    self.resetAuthorisation()
                    self.logger.error("Failed to fetch MusicKit Developer Token")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func authenticateWithToken(userToken: String) {
        self.AM_API.AM_USER_TOKEN = userToken
        try? self.AM_API.initialiseAMNetworking()
        self.isAuthorised = true
    }
    
    func resetAuthorisation() {
        self.AM_API.unauthorise()
        self.isAuthorised = false
    }
    
}
