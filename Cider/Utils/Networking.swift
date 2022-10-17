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
        return try await withCheckedThrowingContinuation { continuation in
            var newHeaders = headers ?? [:]
            newHeaders.merge(dict: defaultHeaders)
            HTTP.New(baseURL.appendingPathComponent(endpoint).absoluteString, method: method, headers: newHeaders) { response in
                if let error = response.error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: response)
            }?.run()
        }
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
    
}
