//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation

class Diagnostic {
    
    static var cpuName: String {
        get {
            return Process.processor
        }
    }
    
    private static let NATIVE_EXECUTION = Int32(0), EMULATED_EXECUTION = Int32(1), UNKONWN_EXECUTION = -Int32(1)
    
    static var processIsTranslated: Int32 {
        get {
            var ret = Int32(0)
            var size = ret.bitWidth / 8
            let result = sysctlbyname("sysctl.proc_translated", &ret, &size, nil, 0)
            if result == -1 {
                if (errno == ENOENT){
                    return 0
                }
                return -1
            }
            return ret
        }
    }
    
    static var processIsTranslatedStr: String {
        get {
            switch self.processIsTranslated {
                
            case NATIVE_EXECUTION:
                return "Native"
                
            case EMULATED_EXECUTION:
                return "Rosetta"
                
            default:
                return "Unknown"
                
            }
        }
    }
    
    static var macSerialNumber: String? {
        get {
            let platformExpert = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice") )
            
            guard platformExpert > 0 else {
                return nil
            }
            
            guard let serialNumber = (IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0).takeUnretainedValue() as? String)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
                return nil
            }
            
            IOObjectRelease(platformExpert)
            
            return serialNumber
        }
    }
    
    static var macOSFullVersionString: String {
        get {
            let os = ProcessInfo().operatingSystemVersion
            return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
        }
    }
    
    static var macOSName: String {
        get {
            return "macOS \(Process.stringFromTerminal(command: "awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | awk -F 'macOS ' '{print $NF}' | awk '{print substr($0, 0, length($0)-1)}'"))"
        }
    }
    
    #if DEBUG
    static let isDebug = true
    #else
    static let isDebug = false
    #endif
    
}
