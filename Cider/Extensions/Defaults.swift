//
//  Defaults.swift
//  Cider
//
//  Created by Sherlock LUK on 25/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Defaults

enum AudioQuality: Int, Defaults.Serializable {
    case Standard = 64, High = 256, Lossless = 0
}

extension Defaults.Keys {
    
    static let audioQuality = Key<AudioQuality>("audioQuality", default: .High)
    static let playbackAutoplay = Key<Bool>("playbackAutoplay", default: true)
    
    static let signInMethod = Key<SignInMethod?>("signInMethod")
    
    static let shareAnalytics = Key<Bool>("shareAnalytics", default: false)
    static let launchedBefore = Key<Bool>("launchedBefore", default: false)
    static let lastLaunchDate = Key<Date>("lastLaunchDate", default: .now)
    static let neverShowDonationPopup = Key<Bool>("neverShowDonationPopup", default: false)
    static let usePretendardFont = Key<Bool>("usePretendardFont", default: false)
    
    static let sidebarWidth = Key<Double>("sidebarWidth", default: 250.0)
    static let showSidebarAtLaunch = Key<Bool>("showSidebarAtLaunch", default: true)
    
    #if DEBUG
    static let debugOpenWebInspectorAutomatically = Key<Bool>("openWebInspectorAutomatically", default: false)
    static let debugHideFrequentWSRequests = Key<Bool>("hideFrequentWSRequests", default: true)
    #endif
    
}
