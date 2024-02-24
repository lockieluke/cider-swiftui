//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import IOKit.ps

class Diagnostic {
    
#if os(macOS)
    static var cpuName: String {
        return Process.processor
    }
    
    private static let NATIVE_EXECUTION = Int32(0), EMULATED_EXECUTION = Int32(1), UNKONWN_EXECUTION = -Int32(1)
    
    static var processIsTranslated: Int32 {
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
    
    static var hasBattery: Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(), let sources: NSArray = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() else {
            return false
        }
        
        for ps in sources {
            if let dict = IOPSGetPowerSourceDescription(snapshot, ps as CFTypeRef)?.takeUnretainedValue() as? NSDictionary,
               let type = dict[kIOPSTransportTypeKey] as? String,
               type == kIOPSInternalType {
                return true
            }
        }
        return false
    }
    
    static var processIsTranslatedStr: String {
        switch self.processIsTranslated {
            
        case NATIVE_EXECUTION:
            return "Native"
            
        case EMULATED_EXECUTION:
            return "Rosetta"
            
        default:
            return "Unknown"
            
        }
    }
    
    static var macSerialNumber: String? {
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
    
    static var modelIdentifier: String? {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        var modelIdentifier: String?
        
        if let modelData = IORegistryEntryCreateCFProperty(service, "model" as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as? Data {
            if let modelIdentifierCString = String(data: modelData, encoding: .utf8)?.cString(using: .utf8) {
                modelIdentifier = String(cString: modelIdentifierCString)
            }
        }
        
        IOObjectRelease(service)
        return modelIdentifier
    }
    
    static var deviceArchitecture: String? {
        var sysInfo = utsname()
        let retVal = uname(&sysInfo)
        var finalString: String? = nil
        
        if retVal == EXIT_SUCCESS
        {
            let bytes = Data(bytes: &sysInfo.machine, count: Int(_SYS_NAMELEN))
            finalString = String(data: bytes, encoding: .utf8)
        }
        
        // _SYS_NAMELEN will include a billion null-terminators. Clear those out so string comparisons work as you expect.
        return finalString?.trimmingCharacters(in: CharacterSet(charactersIn: "\0"))
    }
    
    static var macOSFullVersionString: String {
        let os = ProcessInfo().operatingSystemVersion
        return "\(os.majorVersion).\(os.minorVersion).\(os.patchVersion)"
    }
    
    static var macOSName: String {
        return "macOS \(Process.stringFromTerminal(command: "awk '/SOFTWARE LICENSE AGREEMENT FOR macOS/' '/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/en.lproj/OSXSoftwareLicense.rtf' | awk -F 'macOS ' '{print $NF}' | awk '{print substr($0, 0, length($0)-1)}'"))"
    }
    
    static var macOSVersion: OperatingSystemVersion {
        return ProcessInfo.processInfo.operatingSystemVersion
    }
#endif
    
#if DEBUG
    static let isDebug = true
#else
    static let isDebug = false
#endif
    
}
