//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import SwiftyJSON
import Starscream
import Throttler

enum HTTPMethod : String {
    case GET = "GET", POST = "POST", PUT = "PUT", DELETE = "DELETE"
}

struct HTTPResponse {
    
    let data: Data
    
}

enum CiderWSError : Error {
    
case failedToCreateJSON,
    wsNotConnected(String)
    
}

class CiderWSProvider {
    
    struct WebSocketCallbackEvent {
        
        let onEvent: (_ responseBody: JSON) -> Void
        let id: String
        
    }
    
    private let baseURL: URL
    private let wsTarget: WSTarget
    private let logger: Logger
    private var defaultBody: JSON?
    private var defaultHeaders: [String : String]?
    private let socket: WebSocket
    private var callbacksPool: [WebSocketCallbackEvent] = []
    private var isReady = false
    
    var delegate: WebSocketDelegate? {
        didSet {
            self.socket.delegate = delegate
        }
    }
    
    init(baseURL: URL, wsTarget: WSTarget = .Unknown, defaultBody: JSON? = nil, defaultHeaders: [String : String]? = nil) {
        var request = URLRequest(url: baseURL)
        request.timeoutInterval = 5
        request.allHTTPHeaderFields = defaultHeaders
        let socket = WebSocket(request: request, engine: NativeEngine())
        
        self.baseURL = baseURL
        self.logger = Logger(label: "CiderWSProvider \(baseURL)")
        self.defaultBody = defaultBody
        self.defaultHeaders = defaultHeaders
        self.socket = socket
        self.wsTarget = wsTarget
    }
    
    deinit {
        self.socket.disconnect()
    }
    
    func connect() {
        socket.onEvent = { event in
            self.isReady = true
            
            switch event {
            case .text(let text):
                guard let json = try? JSON(data: text.data(using: .utf8)!) else {
                    self.logger.error("Could not parse response body from WS: \(text)")
                    return
                }
                guard let requestId = json["requestId"].string else {
                    self.logger.error("WS Response does not contain requestId: \(text)")
                    return
                }
                
                DispatchQueue.main.async {
                    WSModal.shared.traffic.append(WSTrafficRecord(target: self.wsTarget, rawJSONString: text, dateSent: .now, trafficType: .Receive, requestId: requestId))
                }
                
                self.callbacksPool.forEach { callback in
                    if callback.id == requestId {
                        callback.onEvent(json)
                    }
                }
                break
                
            default:
                break
            }
        }
        self.socket.connect()
    }
    
    func request(_ route: String, body: [String: Any]? = nil) async throws {
        let lock = NSLock()
        return try await withUnsafeThrowingContinuation { continuation in
            if !self.isReady {
                continuation.resume(throwing: CiderWSError.wsNotConnected("WebSockets connection is not ready"))
                return
            }
            let requestId = UUID().uuidString
            var requestBody = JSON([
                "route": route.unescaped,
                "requestId": requestId
            ])
            if let body = body {
                try? requestBody.merge(with: JSON(body))
            }
            if let defaultBody = self.defaultBody {
                try? requestBody.merge(with: defaultBody)
            }
            
            self.callbacksPool.append(WebSocketCallbackEvent(onEvent: { responseBody in
                defer {
                    self.callbacksPool.removeAll(where: { callback in callback.id == requestId })
                    lock.unlock()
                }
                lock.lock()
                
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }, id: requestId))
            guard let requestBodyString = requestBody.rawString(.utf8) else {
                self.logger.error("Failed to create string of WS request body", displayCross: true)
                continuation.resume(throwing: CiderWSError.failedToCreateJSON)
                return
            }

            DispatchQueue.main.async {
                Throttler.throttle(delay: .milliseconds(100), shouldRunImmediately: false) {
                    WSModal.shared.traffic.append(WSTrafficRecord(target: self.wsTarget, rawJSONString: requestBodyString, dateSent: .now, trafficType: .Send, requestId: requestId))
                }
            }
            self.socket.write(string: requestBodyString)
        }
    }
    
}

class NetworkingProvider {
    
    private let baseURL: URL
    private let logger: Logger
    private static let sharedLogger = Logger(label: "Shared Networking Provider")
    private var defaultHeaders: [String : String]
    
    init(baseURL: URL, defaultHeaders: [String : String]? = nil) {
        self.logger = Logger(label: "Networking Provider \(baseURL)")
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders ?? [:]
    }
    
    func setDefaultHTTPHeaders(headers: [String : String]) {
        self.defaultHeaders = headers
    }
    
    func request(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil, bodyContentType: String = "application/x-www-form-urlencoded", acceptContentType: String = "application/json") async throws -> HTTPResponse {
        var newHeaders = self.defaultHeaders
        newHeaders.merge(dict: self.defaultHeaders)
        guard let urlString = self.baseURL.appendingPathComponent(endpoint).absoluteString.removingPercentEncoding else {
            throw NSError(domain: "Failed to compose URL String", code: 1)
        }
        return try await NetworkingProvider.request(urlString, method: method, headers: newHeaders, body: body, bodyContentType: bodyContentType, acceptContentType: acceptContentType)
    }
    
    func requestJSON(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil, bodyContentType: String = "application/x-www-form-urlencoded", acceptContentType: String = "application/json") async throws -> JSON {
        let json: JSON
        let response: HTTPResponse
        do {
            response = try await request(endpoint, method: method, headers: headers, body: body, bodyContentType: bodyContentType, acceptContentType: acceptContentType)
            json = try JSON(data: response.data)
        } catch {
            throw error
        }
        return json
    }
    
    static func request(_ endpoint: String, method: HTTPMethod = .GET, headers: [String : String]? = nil, body: [String : Any]? = nil, bodyContentType: String = "application/x-www-form-urlencoded", acceptContentType: String = "application/json") async throws -> HTTPResponse {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.allHTTPHeaderFields = headers
        request.httpMethod = method.rawValue
        if let body = body {
            if method != .GET {
                request.addValue(bodyContentType, forHTTPHeaderField: "Content-Type")
                
                if bodyContentType == "application/x-www-form-urlencoded" {
                    var values: String = ""
                    for bodyValue in body {
                        values.append("\(values.isEmpty ? "" : "&")\(bodyValue.key)=\(bodyValue.value)")
                    }
                    
                    request.httpBody = values.data(using: .utf8)
                }
                
                if bodyContentType == "application/json" {
                    do {
                        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                    } catch {
                        self.sharedLogger.error("Failed to serialise JSON \(endpoint): \(error)")
                    }
                }
            }
        }
        
        var responseData: Data
        do {
            let (data, res) = try await URLSession.shared.data(for: request)
            if let res = res as? HTTPURLResponse, res.statusCode != 200, let urlString = res.url?.absoluteString, let response = String(data: data, encoding: .utf8) {
                throw NSError(domain: "Expected HTTP Status: 200 but received \(res.statusCode): \(urlString) \(response)", code: 1)
            }
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
            sharedLogger.error("Error creating socket: \(errno)")
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
