//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import WebKit

extension WKWebView {

    @discardableResult
    func evaluateJavaScriptAsync(_ str: String) async throws -> Any? {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Any?, Error>) in
            DispatchQueue.main.async {
                self.evaluateJavaScript(str) { data, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: data)
                    }
                }
            }
        }
    }
}
