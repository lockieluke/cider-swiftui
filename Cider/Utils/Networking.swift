//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftHTTP
import SwiftyJSON

class NetworkingProvider {
    
    private let baseURL: URL
    private var defaultHeaders: [String : String]
    
    init(baseURL: URL, defaultHeaders: [String : String]? = nil) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders ?? [:]
    }
    
    func setDefaultHTTPHeaders(headers: [String : String]) {
        self.defaultHeaders = headers
    }
    
    func request(_ endpoint: String, method: HTTPVerb = .GET, headers: [String : String]? = nil) async throws -> Response {
        var newHeaders = self.defaultHeaders
        newHeaders.merge(dict: self.defaultHeaders)
        return try await NetworkingProvider.request(self.baseURL.appendingPathComponent(endpoint).absoluteString, method: method, headers: newHeaders)
    }
    
    func requestJSON(_ endpoint: String, method: HTTPVerb = .GET, headers: [String : String]? = nil) async throws -> JSON {
        let json: JSON
        let response: Response
        do {
            response = try await request(endpoint, method: method, headers: headers)
            json = try JSON(data: response.data)
        } catch {
            throw error
        }
        return json
    }
    
    static func request(_ endpoint: String, method: HTTPVerb = .GET, headers: [String : String]? = nil) async throws -> Response {
        return try await withCheckedThrowingContinuation { continuation in
            HTTP.New(endpoint, method: method, headers: headers) { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: response)
            }?.run()
        }
    }
    
    static func findFreeLocalPort() -> UInt16 {
        var port: UInt16 = 8000;
        
        let socketFD = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if socketFD == -1 {
            print("Error creating socket: \(errno)")
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
    
}
