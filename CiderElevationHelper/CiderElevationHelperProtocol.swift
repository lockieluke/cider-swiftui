//
//  CiderElevationHelperProtocol.swift
//  CiderElevationHelper
//
//  Created by Sherlock LUK on 22/11/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation

@objc protocol CiderElevationHelperProtocol {
    
    func initialiseDiscordRpc()
    
    @objc func rpcSetActivityState(state: String)
    
    @objc func rpcSetActivityDetails(details: String)
    
    @objc func rpcSetActivityTimestamps(start: Int64, end: Int64)
    
    @objc func rpcClearActivity()
    
    @objc func rpcUpdateActivity()
    
    @objc func rpcSetActivityAssets(largeImage: String, largeText: String, smallImage: String, smallText: String)
    
    func cleanup()
}
