//
//  Analytics.swift
//  Cider
//
//  Created by Sherlock LUK on 28/01/2024.
//  Copyright © 2024 Cider Collective. All rights reserved.
//

import Foundation
import Defaults
// hacky way to stop hot reload from complaining about missing module
#if canImport(Sentry)
import Sentry
#endif

class Analytics {
    
    static let shared = Analytics()
    
    func startSentry() {
        self.configureSentryScope()
        
        #if canImport(Sentry)
        SentrySDK.start { options in
            options.dsn = Bundle.main.object(forInfoDictionaryKey: "SENTRY_DSN_URL") as? String
            #if DEBUG
            options.debug = true
            options.diagnosticLevel = .warning
            #endif
            options.environment = Diagnostic.isDebug ? "debug" : "production"
            
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
            
            options.attachStacktrace = true
            options.enableMetricKit = true
            options.enableTimeToFullDisplayTracing = true
            options.swiftAsyncStacktraces = true
            
            options.enabled = Defaults[.shareCrashReports]
        }
        #endif
    }
    
    func configureSentryScope() {
        #if canImport(Sentry)
        SentrySDK.configureScope { scope in
            scope.setLevel(.warning)
        }
        #endif
    }
    
    func stopSentry() {
        #if canImport(Sentry)
        SentrySDK.close()
        #endif
    }
    
}
