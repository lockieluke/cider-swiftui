//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON
import Starscream

enum HTTPMethod : String {
    case GET = "GET",
    POST = "POST"
}

struct HTTPResponse {
    
    let data: Data
    
}

enum CiderWSError : Error {
    
case failedToCreateJSON
    
}

class CiderWSProvider {
    
    struct WebSocketCallbackEvent {
        
        let onEvent: (WebSocketEvent) -> Void
        let id: String
        
    }
    
    private let baseURL: URL
    private var defaultBody: JSON?
    private var defaultHeaders: [String : String]?
    private let socket: WebSocket
    private var callbacksPool: [WebSocketCallbackEvent] = []
    
    var delegate: WebSocketDelegate? {
        didSet {
            self.socket.delegate = delegate
        }
    }
    
    init(baseURL: URL, defaultBody: JSON? = nil, defaultHeaders: [String : String]? = nil) {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = 5
        request.allHTTPHeaderFields = defaultHeaders
        let socket = WebSocket(request: request, engine: NativeEngine())
        
        self.baseURL = baseURL
        self.defaultBody = defaultBody
        self.defaultHeaders = defaultHeaders
        self.socket = socket
    }
    
    deinit {
        self.socket.disconnect()
    }
    
    func connect() {
        socket.onEvent = { event in
            self.callbacksPool.forEach { callback in
                callback.onEvent(event)
            }
        }
        self.socket.connect()
    }
    
    func request(_ route: String, body: [String: Any]? = nil) async throws {
        let lock = NSLock()
        return try await withUnsafeThrowingContinuation() { continuation in
            let requestId = UUID().uuidString
            var requestBody = JSON([
                "route": route.unescaped,
                "request-id": requestId
            ])
            if let body = body {
                try? requestBody.merge(with: JSON(body))
            }
            if let defaultBody = self.defaultBody {
                try? requestBody.merge(with: defaultBody)
            }
            
            self.callbacksPool.append(WebSocketCallbackEvent(onEvent: { event in
                defer {
                    self.callbacksPool.removeAll(where: { callback in callback.id == requestId })
                    lock.unlock()
                }
                lock.lock()
                
                switch event {
                    
                case .text(let text):
                    let responseBody = try? JSON(data: text.data(using: .utf8)!)
                    DispatchQueue.main.async {
                        if responseBody?["request-id"].stringValue == requestId {
                            continuation.resume()
                        }
                    }
                    break
                    
                default:
                    break
                }
            }, id: requestId))
            guard let requestBodyString = requestBody.rawString(.utf8) else {
                print("Failed to create string of WS request body")
                continuation.resume(throwing: CiderWSError.failedToCreateJSON)
                return
            }

            self.socket.write(string: requestBodyString)
        }
    }
    
}

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
    
    func request(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil) async throws -> HTTPResponse {
        var newHeaders = self.defaultHeaders
        newHeaders.merge(dict: self.defaultHeaders)
        return try await NetworkingProvider.request(self.baseURL.appendingPathComponent(endpoint).absoluteString, method: method, headers: newHeaders, body: body)
    }
    
    func requestJSON(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil) async throws -> JSON {
        let json: JSON
        let response: HTTPResponse
        do {
            response = try await request(endpoint, method: method, headers: headers, body: body)
            json = try JSON(data: response.data)
        } catch {
            throw error
        }
        return json
    }
    
    static func request(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil) async throws -> HTTPResponse {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        if let body = body {
            if method != .GET {
                request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
                request.setValue(NSLocalizedString("lang", comment: ""), forHTTPHeaderField:"Accept-Language");
                var values: String = ""
                for bodyValue in body {
                    values.append("\(values.isEmpty ? "" : "&")\(bodyValue.key)=\(bodyValue.value)")
                }
                
                request.httpBody = values.data(using: .utf8)
            }
        }
        
        var responseData: Data
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            responseData = data
        } catch {
            throw error
        }
        
        return HTTPResponse(data: responseData)
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
