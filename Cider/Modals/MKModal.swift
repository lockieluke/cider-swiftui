//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import MusicKit
import StoreKit

class MKModal : ObservableObject {
    
    public static let shared = MKModal()
    
    @Published public var isAuthorised = false
    @Published public var amAuthError: Error?
    @Published public var hasDeveloperToken = false
    
    public let AM_API = AMAPI()
    
    init() {}
    
    func authorise() {
        self.AM_API.requestSKAuthorisation { skStatus in
            if skStatus != .authorized {
                self.resetAuthorisation()
            }
            print("StoreKit successfully authorised")
            
            Task {
                let developerToken = await self.AM_API.fetchMKDeveloperToken()
                DispatchQueue.main.async {
                    self.hasDeveloperToken = true
                    CiderPlayback.shared.setDeveloperToken(developerToken: developerToken)
                }
                self.AM_API.requestMKAuthorisation { mkStatus in
                    if mkStatus != .authorized {
                        self.resetAuthorisation()
                    }
                    print("MusicKit successfully authorised")
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
