//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON

enum AudioQuality: Int {
    
    case Standard = 64, High = 256
    
}

struct Prefs {
    
    var openWebInspectorAutomatically = false
    var hideFrequentWSRequests = true
    var audioQuality: AudioQuality = .Standard
    
    var json: JSON {
        get {
            return JSON([
                "debug": [
                    "openWebInspectorAutomatically": openWebInspectorAutomatically,
                    "hideFrequentWSRequests": hideFrequentWSRequests
                ],
                "audio": [
                    "quality": audioQuality.rawValue
                ]
            ])
        }
    }
    
    var rawJSONString: String {
        get {
            return self.json.rawString(.utf8) ?? "{}"
        }
    }
    
}

class PrefModal: ObservableObject {    
    
    @Published var prefs = Prefs() {
        didSet {
            self.saveSettings()
        }
    }
    
    private let logger = Logger(label: "UserPreferences")
    
    var appPrefsDir: URL {
        get {
            do {
                return try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(Bundle.main.displayName)
            } catch {
                return URL(string: FileManager.default.currentDirectoryPath)!.appendingPathComponent("Cider/config.json")
            }
        }
    }
    
    var configPath: URL {
        get {
            return self.appPrefsDir.appendingPathComponent("config.json")
        }
    }
    
    var doesConfigExist: Bool {
        get {
            return (try? self.configPath.checkResourceIsReachable()) ?? false
        }
    }
    
    init() {
        self.restoreSettings()
    }
    
    func restoreSettings() {
        if doesConfigExist {
            do {
                let configData = try Data(contentsOf: self.configPath)
                let json = try JSON(data: configData)
                
                self.prefs = Prefs(
                    openWebInspectorAutomatically: json["debug"]["openWebInspectorAutomatically"].bool ?? false,
                    hideFrequentWSRequests: json["debug"]["hideFrequentWSRequests"].bool ?? true,
                    audioQuality: AudioQuality(rawValue: json["audio"]["quality"].int ?? 64) ?? .Standard
                )
            } catch {
                self.logger.error("Failed to read from config file: \(error)", displayCross: true)
            }
        } else {
            self.saveSettings()
        }
    }
    
    func saveSettings() {
        if let rawString = self.prefs.json.rawString(.utf8) {
            do {
                try rawString.write(to: self.configPath, atomically: false, encoding: .utf8)
            } catch {
                self.logger.error("Failed to write to config file", displayCross: true)
            }
        }
    }
    
}
