//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON
import Throttler
import Alamofire
import Cache

class Networking {
    
    static let logger = Logger(label: "Networking")
    private static let DEFAULT_UA: String = "Mozilla/5.0 (Macintosh; Intel Mac OS X 12_5_1) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.6 Safari/605.1.15"
    private static var storage: Storage<String, String>?
    
    static func initialise() {
        let diskConfig = DiskConfig(name: "Cider-Networking")
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 10, totalCostLimit: 10)
        
        do {
            self.storage = try Storage<String, String>(
                diskConfig: diskConfig,
                memoryConfig: memoryConfig,
                transformer: TransformerFactory.forCodable(ofType: String.self)
            )
        } catch {
            self.logger.error("Failed to initialise Networking Cache: \(error)")
            self.storage = nil
        }
        
        do {
            try self.storage?.removeExpiredObjects()
        } catch {
            self.logger.error("Failed to remove expired cache objects: \(error)")
        }
    }
    
    static func findLatestWebViewUA() async -> String {
//        if let cachedLatestUA = try? self.storage?.object(forKey: "latest-ua") {
//            return cachedLatestUA
//        }
//        
//        let res = await AF.request("https://jnrbsn.github.io/user-agents/user-agents.json", headers: [
//            "Accept": "application/json"
//        ]).validate().serializingData().response
//        
//        if res.error.isNil, let data = res.data, let json = try? JSON(data: data), let uaArray = json.array {
//            let ua = uaArray[19].stringValue
//            
//            do {
//                try self.storage?.setObject(ua, forKey: "latest-ua", expiry: .date(Date().addingTimeInterval(7 * 60 * 60)))
//            } catch {
//                self.logger.error("Failed to cache latest UAs: \(error)")
//            }
//            
//            return ua
//        }
        
        return self.DEFAULT_UA
    }
    
    static func clearUserAgentCache() {
        do {
            try self.storage?.removeObject(forKey: "latest-ua")
        } catch {
            self.logger.error("Failed to clear UA cache: \(error)")
        }
    }
    
    static func findFreeLocalPort() -> UInt16 {
        var port: UInt16 = 8000;
        
        let socketFD = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if socketFD == -1 {
            self.logger.error("Error creating socket: \(errno)")
            return port;
        }
        
        var hints = addrinfo(
            ai_flags: AI_PASSIVE,
            ai_family: AF_INET,
            ai_socktype: SOCK_STREAM,
            ai_protocol: 0,
            ai_addrlen: 0,
            ai_canonname: nil,
            ai_addr: nil,
            ai_next: nil
        );
        
        var addressInfo: UnsafeMutablePointer<addrinfo>? = nil;
        var result = getaddrinfo(nil, "0", &hints, &addressInfo);
        if result != 0 {
            //print("Error getting address info: \(errno)")
            close(socketFD);
            
            return port;
        }
        
        result = Darwin.bind(socketFD, addressInfo!.pointee.ai_addr, socklen_t(addressInfo!.pointee.ai_addrlen));
        if result == -1 {
            //print("Error binding socket to an address: \(errno)")
            close(socketFD);
            
            return port;
        }
        
        result = Darwin.listen(socketFD, 1);
        if result == -1 {
            //print("Error setting socket to listen: \(errno)")
            close(socketFD);
            
            return port;
        }
        
        var addr_in = sockaddr_in();
        addr_in.sin_len = UInt8(MemoryLayout.size(ofValue: addr_in));
        addr_in.sin_family = sa_family_t(AF_INET);
        
        var len = socklen_t(addr_in.sin_len);
        result = withUnsafeMutablePointer(to: &addr_in, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                return Darwin.getsockname(socketFD, $0, &len);
            }
        });
        
        if result == 0 {
            port = addr_in.sin_port;
        }
        
        Darwin.shutdown(socketFD, SHUT_RDWR);
        close(socketFD);
        
        return port;
    }
    
    static func isPortOpen(port: in_port_t) -> Bool {
        return NativeUtilsWrapper.nativeUtilsGlobal.is_port_open(port)
    }
    
}
