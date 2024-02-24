//
//  CiderElevationHelper.swift
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

class CiderElevationHelper: NSObject, CiderElevationHelperProtocol {
    
    private let discordRpc = DiscordRPCAgent()
    
    override init() {
        ProcessInfo.processInfo.disableAutomaticTermination("DiscordRPCHelper")
    }
    
    func cleanup() {
        self.discordRpc.stop()
        exit(0)
    }
    
    func rpcSetActivityState(state: String) {
        self.discordRpc.setActivityState(state)
    }
    
    func rpcSetActivityDetails(details: String) {
        self.discordRpc.setActivityDetails(details)
    }
    
    func rpcSetActivityTimestamps(start: Int64, end: Int64) {
        self.discordRpc.setActivityTimestamps(start, end)
    }
    
    func rpcClearActivity() {
        self.discordRpc.clearActivity()
    }
    
    func rpcUpdateActivity() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.discordRpc.updateActivity()
        }
    }
    
    func rpcSetActivityAssets(largeImage: String, largeText: String, smallImage: String, smallText: String) {
        self.discordRpc.setActivityAssets(largeImage, largeText, smallImage, smallText)
    }
    
    func initialiseDiscordRpc() {
        self.discordRpc.start()
    }
    
    func isDiscordInstalled(withReply reply: @escaping (Bool) -> Void) {
        let bundleIdentifier = "com.hnc.Discord"
        
        reply(!NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier).isNil)
    }
    
    func retrieveDiscordUsername(withReply reply: @escaping (String?) -> Void) {
        guard let scopev3 = try? Folder.home.subfolder(named: "Library").subfolder(named: "Application Support").subfolder(named: "discord").subfolder(named: "sentry").file(named: "scope_v3.json"), let data = try? scopev3.read(), let json = try? JSON(data: data) else {
            reply(nil)
            return
        }
        
        reply(json["scope"]["_user"]["username"].string)
    }
    
    func retrieveDiscordId(withReply reply: @escaping (String?) -> Void) {
        guard let scopev3 = try? Folder.home.subfolder(named: "Library").subfolder(named: "Application Support").subfolder(named: "discord").subfolder(named: "sentry").file(named: "scope_v3.json"), let data = try? scopev3.read(), let json = try? JSON(data: data) else {
            reply(nil)
            return
        }
        
        reply(json["scope"]["_user"]["id"].string)
    }
    
    func retrieveAppleIdInformation(withReply reply: @escaping (Data?) -> Void) {
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
                
                reply(response)
            } catch {
                fatalError("Error retrieving Apple ID info: \(error.localizedDescription)")
            }
        }
        
        reply(nil)
    }
    
}
