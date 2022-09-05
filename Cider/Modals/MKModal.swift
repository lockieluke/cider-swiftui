//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import MusicKit
import StoreKit

class MKModal : ObservableObject {
    
    public static let shared = MKModal()
    
    @Published public var isAuthorised = false
    @Published public var isCapableAM = false
    @Published public var amAuthError: Error?
    
    public let AM_API = AMAPI()
    public let appleAuth = AppleAuth()
    private var AM_USER_TOKEN: String = "not initialised"
    
    init() {}
    
    func authorise() {
        self.AM_API.requestSKAuthorisation { skStatus in
            if skStatus != .authorized {
                self.resetAuthorisation()
            }
            print("StoreKit successfully authorised")
            
            Task {
                await self.AM_API.fetchMKDeveloperToken()
                self.AM_API.requestMKAuthorisation { mkStatus in
                    if mkStatus != .authorized {
                        self.resetAuthorisation()
                    }
                    print("MusicKit successfully authorised")
                    
                    self.AM_API.checkAMSubscription { hasSubscription in
                        if !hasSubscription {
                            self.resetAuthorisation()
                            print("User does not have an active Apple Music subscription")
                        }
                        
                        self.AM_API.fetchMKUserToken { isAuthorised, userToken, error in
                            if let error = error {
                                self.amAuthError = error
                                self.resetAuthorisation()
                                return
                            }
                            
                            if isAuthorised {
                                guard let userToken = userToken else {
                                    self.resetAuthorisation()
                                    return
                                }
                                print("Successfully retrieved MK User Token: \(userToken)")
                                self.AM_USER_TOKEN = userToken
                                self.isAuthorised = true
                                self.isCapableAM = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func resetAuthorisation() {
        self.isAuthorised = false
        self.isCapableAM = false
    }
    
}
