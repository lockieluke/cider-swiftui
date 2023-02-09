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
    
    func authorise() async -> String {
        self.logger.info("Fetching MusicKit Developer Token")
        return await withCheckedContinuation { continuation in
            self.AM_API.requestSKAuthorisation { skStatus in
                if skStatus != .authorized {
                    self.resetAuthorisation()
                }
                Task {
                    let developerToken = await self.AM_API.fetchMKDeveloperToken()
                    DispatchQueue.main.async {
                        self.hasDeveloperToken = true
                        self.ciderPlayback.setDeveloperToken(developerToken: developerToken, mkModal: self)
                        self.logger.success("Successfully fetched MusicKit Developer Token", displayTick: true)
                        continuation.resume(returning: developerToken)
                    }
                    self.AM_API.requestMKAuthorisation { mkStatus in
                        if mkStatus != .authorized {
                            self.resetAuthorisation()
                        }
                    }
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
