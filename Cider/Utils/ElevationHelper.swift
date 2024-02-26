//
//  ElevationHelper.swift
//  Cider
//
//  Created by Sherlock LUK on 24/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import ZippyJSON
import SwiftyXPC

class ElevationHelper {
    
    static let shared = try! ElevationHelper()
    
    private let connection: XPCConnection
    private let logger: Logger
    private var pid: Int32? = nil
    
    private init() throws {
        let connection = try XPCConnection(type: .remoteService(bundleID: "com.cidercollective.CiderElevationHelper"))
        let logger = Logger(label: "ElevatedHelper")
        
        connection.errorHandler = { _, error in
            logger.error("The connection to the XPC service received an error: \(error.localizedDescription)")
        }
        
        connection.resume()
        
        self.connection = connection
        self.logger = logger
    }
    
    @MainActor
    func terminate() {
        
    }
    
    func rpcSetActivityState(state: String) async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcSetActivityState, request: state)
    }
    
    func rpcSetActivityDetails(details: String) async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcSetActivityDetails, request: details)
    }
    
    func rpcSetActivityTimestamps(start: Int64, end: Int64) async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcSetActivityTimestamps, request: RPCTimestamp(start: start, end: end))
    }
    
    func rpcClearActivity() async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcClearActivity)
    }
    
    func rpcUpdateActivity() async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcUpdateActivity)
    }
    
    func rpcSetActivityAssets(largeImage: String, largeText: String, smallImage: String, smallText: String) async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.rpcSetActivityAssets, request: RPCAssets(largeImage: largeImage, largeText: largeText, smallImage: smallImage, smallText: smallText))
    }
    
    func initialiseDiscordRpc() async {
        await self.sendMessage(name: CiderElevationHelperCommandSet.initialiseDiscordRpc)
    }
    
    func isDiscordInstalled() async -> Bool {
        return (try? await self.connection.sendMessage(name: CiderElevationHelperCommandSet.isDiscordInstalled)) ?? false
    }
    
    func retrieveDiscordUsername() async -> String? {
        return try? await self.connection.sendMessage(name: CiderElevationHelperCommandSet.retrieveDiscordUsername)
    }
    
    func retrieveDiscordId() async -> String? {
        return try? await self.connection.sendMessage(name: CiderElevationHelperCommandSet.retrieveDiscordId)
    }
    
    func retrieveAppleIdInformation() async -> AppleIdInformation? {
        return try? await self.connection.sendMessage(name: CiderElevationHelperCommandSet.retrieveAppleIdInformation)
    }
    
    private func sendMessage(name: String, request: (Codable & Decodable)? = nil) async {
        do {
            if request.isNil {
                try await self.connection.sendMessage(name: name)
            } else {
                try await self.connection.sendMessage(name: name, request: request!)
            }
        } catch {
            self.logger.error("Failed to send message: \(error.localizedDescription)")
        }
    }

    
}
