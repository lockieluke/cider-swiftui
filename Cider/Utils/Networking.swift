//
//  Copyright © 2022 Cider Collective. All rights reserved.
//

import Foundation
import SwiftyJSON
import Starscream
import Throttler
import Alamofire
import Cache

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
    private let callbacksQueue = DispatchQueue(label: "com.cidercollective.callbacksQueue")
    
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
        self.socket.onEvent = { event in
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
    
    func request(_ route: String, body: [String: Any]? = nil) async throws -> JSON {
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
            
            callbacksQueue.sync {
                self.callbacksPool.append(WebSocketCallbackEvent(onEvent: { [weak self] responseBody in
                    guard let self = self else { return }
                    
                    self.callbacksPool.removeAll(where: { callback in callback.id == requestId })
                    
                    DispatchQueue.main.async {
                        continuation.resume(returning: responseBody)
                    }
                }, id: requestId))
            }
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
        newHeaders.merge(with: newHeaders, self.defaultHeaders)
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
                        Networking.logger.error("Failed to serialise JSON \(endpoint): \(error)")
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
    
}

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
        if let cachedLatestUA = try? self.storage?.object(forKey: "latest-ua") {
            return cachedLatestUA
        }
        
        let res = await AF.request("https://jnrbsn.github.io/user-agents/user-agents.json", headers: [
            "Accept": "application/json"
        ]).validate().serializingData().response
        
        if res.error.isNil, let data = res.data, let json = try? JSON(data: data), let uaArray = json.array {
            let ua = uaArray[19].stringValue
            
            do {
                try self.storage?.setObject(ua, forKey: "latest-ua", expiry: .date(Date().addingTimeInterval(7 * 60 * 60)))
            } catch {
                self.logger.error("Failed to cache latest UAs: \(error)")
            }
            
            return ua
        }
        
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
