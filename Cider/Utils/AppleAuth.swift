//
//  Copyright © 2022 Cider Collective. All rights reserved.
//  

import Foundation
import Alamofire
import SwiftyJSON

public enum AASecurityCode {
    case device(code: String)
    case sms(code: String, phoneNumberId: Int)
    
    var urlPathComponent: String {
        switch self {
        case .device: return "trusteddevice"
        case .sms: return "phone"
        }
    }
}

struct AppleAuthURLs {
    static let itcServiceKey = URL(string: "https://appstoreconnect.apple.com/olympus/v1/app/config?hostname=itunesconnect.apple.com")!
    static let signIn = URL(string: "https://idmsa.apple.com/appleauth/auth/signin")!
    static let authOptions = URL(string: "https://idmsa.apple.com/appleauth/auth")!
    static let requestSecurityCode = URL(string: "https://idmsa.apple.com/appleauth/auth/verify/phone")!
    static func submitSecurityCode(_ code: AASecurityCode) -> URL { URL(string: "https://idmsa.apple.com/appleauth/auth/verify/\(code.urlPathComponent)/securitycode")! }
    static let trust = URL(string: "https://idmsa.apple.com/appleauth/auth/2sv/trust")!
    static let olympusSession = URL(string: "https://appstoreconnect.apple.com/olympus/v1/session")!
}

enum AAResponseCode: Int {
    
    case SuccessfullyAuthenticated = 200;
    case InvalidUsernameOrPassword = 401;
    case AccountLocked = 403;
    case TwoFARequired = 409;
    case AppleIDAndPrivacyAcknowledgementRequired = 412;
    
}

class AppleAuth {
    
    init() { }
    
    func login(accountName: String, password: String) async {
        guard let authServiceKey = await self.getServiceKey() else { return }
        
        let parameters: [String: Any] = [
            "accountName": accountName,
            "password": password,
            "rememberMe": true
        ]
        let response = await AF.request(AppleAuthURLs.signIn, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: [
            "Content-Type": "application/json",
            "X-Requested-With": "XMLHttpRequest",
            "X-Apple-Widget-Key": authServiceKey,
            "Accept": "application/json, text/javascript"
        ]).validate().serializingData().response
        
        guard let responseCode = response.response?.statusCode else { return }
        
        switch AAResponseCode(rawValue: responseCode) {
            
        default:
            print("Unexpected AppleAuth response")
            break
            
        }
    }
    
    func getServiceKey() async -> String? {
        let response = await AF.request(AppleAuthURLs.itcServiceKey, method: .get).validate().serializingData().response
        if let data = response.data {
            do {
                return try JSON(data: data)["authServiceKey"].stringValue
            } catch {
                print("Error parsing AppleAuth authServiceKey: \(error.localizedDescription)")
            }
        } else {
            print("Error fetching AppleAuth authServiceKey: \(response.error?.localizedDescription ?? "Unkown Error")")
        }
        
        return nil
    }
    
}
