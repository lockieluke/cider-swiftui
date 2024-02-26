//
//  CiderElevationHelperCommandSet.swift
//  CiderElevationHelper
//
//  Created by Sherlock LUK on 26/02/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation

struct RPCAssets: Codable {
    let largeImage: String
    let largeText: String
    let smallImage: String
    let smallText: String
}

struct RPCTimestamp: Codable {
    let start: Int64
    let end: Int64
}

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

struct CiderElevationHelperCommandSet {
    static let cleanup = "com.cidercollective.CiderElevationHelper.cleanup"
    
    static let initialiseDiscordRpc = "com.cidercollective.CiderElevationHelper.initialiseDiscordRpc"
    static let rpcSetActivityState = "com.cidercollective.CiderElevationHelper.rpcSetActivityState"
    static let rpcSetActivityDetails = "com.cidercollective.CiderElevationHelper.rpcSetActivityDetails"
    static let rpcSetActivityTimestamps = "com.cidercollective.CiderElevationHelper.rpcSetActivityTimestamps"
    static let rpcClearActivity = "com.cidercollective.CiderElevationHelper.rpcClearActivity"
    static let rpcUpdateActivity = "com.cidercollective.CiderElevationHelper.rpcUpdateActivity"
    static let rpcSetActivityAssets = "com.cidercollective.CiderElevationHelper.rpcSetActivityAssets"
    
    static let isDiscordInstalled = "com.cidercollective.CiderElevationHelper.isDiscordInstalled"
    static let retrieveDiscordUsername = "com.cidercollective.CiderElevationHelper.retrieveDiscordUsername"
    static let retrieveDiscordId = "com.cidercollective.CiderElevationHelper.retrieveDiscordId"
    
    static let retrieveAppleIdInformation = "com.cidercollective.CiderElevationHelper.retrieveAppleIdInformation"
}
