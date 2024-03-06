//
//  Defaults.swift
//  Cider
//
//  Created by Sherlock LUK on 25/03/2023.
//  Copyright © 2023 Cider Collective. All rights reserved.
//

import Foundation
import Defaults
import SplitView

enum AudioQuality: Int, Defaults.Serializable {
    case Standard = 64, High = 256, Lossless = 0
}

func usingUserDefaults(_ fraction: CGFloat? = nil, key: String) -> FractionHolder {
    let defaultKey = Defaults.Key<CGFloat>(key, default: fraction ?? 0.5)
    
    return FractionHolder(
        fraction,
        getter: { Defaults[defaultKey] },
        setter: { fraction in Defaults[defaultKey] = fraction }
    )
}

extension Defaults.Keys {
    
    static let playbackBackend = Key<PlaybackEngineType>("playbackBackend", default: .MKJS)
    static let audioQuality = Key<AudioQuality>("audioQuality", default: .High)
    static let playbackAutoplay = Key<Bool>("playbackAutoplay", default: true)
    
    static let signInMethod = Key<SignInMethod?>("signInMethod")
    
    static let shareCrashReports = Key<Bool>("shareCrashReports", default: true)
    static let shareAnalytics = Key<Bool>("shareAnalytics", default: true)
    static let launchedBefore = Key<Bool>("launchedBefore", default: false)
    static let lastLaunchDate = Key<Date>("lastLaunchDate", default: .now)
    static let neverShowDonationPopup = Key<Bool>("neverShowDonationPopup", default: false)
    static let usePretendardFont = Key<Bool>("usePretendardFont", default: false)
    static let rootStacksSleepSeconds = Key<Int>("rootStacksSleepSeconds", default: 10)
    
    static let experiments = Key<[CiderExperiment]>("experiments", default: [])
    
    static let sidebarWidth = Key<Double>("sidebarWidth", default: 275.0)
    static let showSidebarAtLaunch = Key<Bool>("showSidebarAtLaunch", default: true)
    
    static let lastShownChangelogs = Key<String?>("lastShownChangelogs")
    static let isLocallyBanned = Key<Bool>("isLocallyBanned", default: false)
    
    #if DEBUG
    static let debugOpenWebInspectorAutomatically = Key<Bool>("openWebInspectorAutomatically", default: false)
    static let debugHideFrequentWSRequests = Key<Bool>("hideFrequentWSRequests", default: true)
    static let enableAtlantis = Key<Bool>("enableAtlantis", default: false)
    #endif
    
}
