//
//  CiderElevationHelper.swift
//  CiderElevationHelper
//
//  Created by Sherlock LUK on 22/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyUtils

class CiderElevationHelper: NSObject, CiderElevationHelperProtocol {
    
    private let discordRpc = DiscordRPCAgent()
    
    override init() {
        ProcessInfo.processInfo.disableAutomaticTermination("DiscordRPCHelper")
    }
    
    @MainActor
    @objc func cleanup() {
        self.discordRpc.stop()
        exit(0)
    }
    
    @MainActor
    @objc func rpcSetActivityState(state: String) {
        self.discordRpc.setActivityState(state)
    }
    
    @MainActor
    @objc func rpcSetActivityDetails(details: String) {
        self.discordRpc.setActivityDetails(details)
    }
    
    @MainActor
    @objc func rpcSetActivityTimestamps(start: Int64, end: Int64) {
        self.discordRpc.setActivityTimestamps(start, end)
    }
    
    @MainActor
    @objc func rpcClearActivity() {
        self.discordRpc.clearActivity()
    }
    
    @MainActor
    @objc func rpcUpdateActivity() {
        self.discordRpc.updateActivity()
    }
    
    @MainActor
    @objc func rpcSetActivityAssets(largeImage: String, largeText: String, smallImage: String, smallText: String) {
        self.discordRpc.setActivityAssets(largeImage, largeText, smallImage, smallText)
    }
    
    @MainActor
    @objc func initialiseDiscordRpc() {
        self.discordRpc.start()
    }
    
}
