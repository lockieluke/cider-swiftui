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
    
    private let logger = Logger(label: "Analytics")
    
    var isArcDefaultBrowser: Bool {
        return self.retrieveUserDefaultBrowser() == "company.thebrowser.Browser"
    }
    
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
        self.logger.success("Started Sentry", displayTick: true)
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
        self.logger.success("Stopped Sentry")
    }
    
    func retrieveUserDefaultBrowser() -> String? {
        let httpUrl = NSURL(string: "http:")!
        let httpsUrl = NSURL(string: "https:")!

        let httpDefaultApp = LSCopyDefaultApplicationURLForURL(httpUrl as CFURL, .all, nil)
        let httpsDefaultApp = LSCopyDefaultApplicationURLForURL(httpsUrl as CFURL, .all, nil)

        if httpDefaultApp != nil {
            if let appName = Bundle(url: httpDefaultApp!.takeRetainedValue() as URL)?.bundleIdentifier {
                if appName.lowercased().contains("arcbrowser") {
                    print("Arc Browser is default for HTTP")
                }
            }
        }

        if httpsDefaultApp != nil {
            if let appName = Bundle(url: httpsDefaultApp!.takeRetainedValue() as URL)?.bundleIdentifier {
                return appName
            }
        }
        
        return nil
    }
    
}
