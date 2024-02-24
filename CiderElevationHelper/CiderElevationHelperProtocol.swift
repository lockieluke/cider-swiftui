//
//  CiderElevationHelperProtocol.swift
//  CiderElevationHelper
//
//  Created by Sherlock LUK on 22/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

struct AppleIdInformation: Codable {
    let isLoggedIn: Bool
    let displayName: String
    let accountId: String
    let accountDescription: String
    let accountUUID: String
    let firstName: String
    let lastName: String
    let isManaged: Bool
    let primaryEmailVerified: Bool
}

@objc protocol CiderElevationHelperProtocol {
    
    func initialiseDiscordRpc()
    func rpcSetActivityState(state: String)
    func rpcSetActivityDetails(details: String)
    func rpcSetActivityTimestamps(start: Int64, end: Int64)
    func rpcClearActivity()
    func rpcUpdateActivity()
    func rpcSetActivityAssets(largeImage: String, largeText: String, smallImage: String, smallText: String)

    func cleanup()
    
    func isDiscordInstalled(withReply reply: @escaping (Bool) -> Void)
    func retrieveDiscordUsername(withReply reply: @escaping (String?) -> Void)
    func retrieveDiscordId(withReply reply: @escaping (String?) -> Void)
    
    func retrieveAppleIdInformation(withReply reply: @escaping (Data?) -> Void)
}
