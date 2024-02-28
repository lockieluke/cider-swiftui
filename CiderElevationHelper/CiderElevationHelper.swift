//
//  main.swift
//  CiderElevationHelper
//
//  Created by Sherlock LUK on 22/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyUtils
import AppKit
import Files
import SwiftyJSON
import SwiftyXPC

@main
class CiderElevationHelper {
    
    private let discordRpc = DiscordRPCAgent()
    
    static func main() {
        ProcessInfo.processInfo.disableAutomaticTermination("DiscordRPCHelper")
        
        do {
            let xpcService = CiderElevationHelper()
            
            // In an actual product, you should always set a real code signing requirement here, for security
            let requirement: String? = nil
            
            let serviceListener = try XPCListener(type: .service, codeSigningRequirement: requirement)
            
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.initialiseDiscordRpc, handler: xpcService.initialiseDiscordRpc)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcSetActivityState, handler: xpcService.rpcSetActivityState)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcSetActivityDetails, handler: xpcService.rpcSetActivityDetails)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcSetActivityTimestamps, handler: xpcService.rpcSetActivityTimestamps)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcClearActivity, handler: xpcService.rpcClearActivity)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcUpdateActivity, handler: xpcService.rpcUpdateActivity)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.rpcSetActivityAssets, handler: xpcService.rpcSetActivityAssets)
            
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.cleanup, handler: xpcService.cleanup)
            
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.isDiscordInstalled, handler: xpcService.isDiscordInstalled)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.retrieveDiscordUsername, handler: xpcService.retrieveDiscordUsername)
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.retrieveDiscordId, handler: xpcService.retrieveDiscordId)
            
            serviceListener.setMessageHandler(name: CiderElevationHelperCommandSet.retrieveAppleIdInformation, handler: xpcService.retrieveAppleIdInformation)
            
            serviceListener.activate()
            fatalError("Should never get here")
        } catch {
            fatalError("Error while setting up XPC service: \(error)")
        }
    }
    
    struct EmptyStruct: Codable {}
    func cleanup(_: XPCConnection, empty: EmptyStruct) {
        self.discordRpc.stop()
        exit(0)
    }
    
    func rpcSetActivityState(_: XPCConnection, state: String) {
        self.discordRpc.setActivityState(state)
    }
    
    func rpcSetActivityDetails(_: XPCConnection, details: String) {
        self.discordRpc.setActivityDetails(details)
    }
    
    func rpcSetActivityTimestamps(_: XPCConnection, timestamps: RPCTimestamp) {
        self.discordRpc.setActivityTimestamps(timestamps.start, timestamps.end)
    }
    
    func rpcClearActivity(_: XPCConnection) {
        self.discordRpc.clearActivity()
    }
    
    func rpcUpdateActivity(_: XPCConnection) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.discordRpc.updateActivity()
        }
    }
    
    func rpcSetActivityAssets(_: XPCConnection, assets: RPCAssets) {
        self.discordRpc.setActivityAssets(assets.largeImage, assets.largeText, assets.smallImage, assets.smallText)
    }
    
    func initialiseDiscordRpc(_: XPCConnection) {
        self.discordRpc.start()
    }
    
    func isDiscordInstalled(_: XPCConnection) async -> Bool {
        let bundleIdentifier = "com.hnc.Discord"
        
        return !NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier).isNil
    }
    
    func retrieveDiscordUsername(_: XPCConnection) async -> String? {
        guard let scopev3 = try? Folder.home.subfolder(named: "Library").subfolder(named: "Application Support").subfolder(named: "discord").subfolder(named: "sentry").file(named: "scope_v3.json"), let data = try? scopev3.read(), let json = try? JSON(data: data) else {
            return nil
        }
        
        return json["scope"]["_user"]["username"].string
    }
    
    func retrieveDiscordId(_: XPCConnection) -> String? {
        guard let scopev3 = try? Folder.home.subfolder(named: "Library").subfolder(named: "Application Support").subfolder(named: "discord").subfolder(named: "sentry").file(named: "scope_v3.json"), let data = try? scopev3.read(), let json = try? JSON(data: data) else {
            return nil
        }
        
        return json["scope"]["_user"]["id"].string
    }
    
    func retrieveAppleIdInformation(_: XPCConnection) -> Data? {
        if let defaults = UserDefaults(suiteName: "MobileMeAccounts"), let dict = (defaults.dictionaryRepresentation()["Accounts"] as? NSArray)?[0] as? [String: Any?] {
            do {
                let response = try JSONEncoder().encode(AppleIdInformation(
                    isLoggedIn: dict["LoggedIn"] as! Bool,
                    displayName: dict["DisplayName"] as! String,
                    accountId: dict["AccountID"] as! String,
                    accountDescription: dict["AccountDescription"] as! String,
                    accountUUID: dict["AccountUUID"] as! String,
                    firstName: dict["firstName"] as! String,
                    lastName: dict["lastName"] as! String,
                    isManaged: dict["isManagedAppleID"] as! Bool,
                    primaryEmailVerified: dict["primaryEmailVerified"] as! Bool
                ))
                
                return response
            } catch {
                print("Error retrieving Apple ID info: \(error.localizedDescription)")
            }
        }
        
        return nil
    }
    
}
