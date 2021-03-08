//
//  Keyserver.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import Alamofire

// Manages all requests to the key server. Key tasks include getting, setting, and removing pins and users.
public class Keyserver {
    
    var client: NetworkingLayer! // used for testing, for now
    var baseUrl:String!
    let headers: HTTPHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/json",
    ]
    init(_ baseUrl:String) {
        self.baseUrl = baseUrl
    }
    
    func setPin(pin:String) {
        Alamofire.AF.request(baseUrl + "", method: .post, parameters: pin)
            .validate(statusCode: 201..<201)
            .responseData { response in
                    switch response.result {
                    case .success:
                        print("Sweet")
                    case let .failure(error):
                        print(error)
                    }
                }
    }
    
    func createKey(pin:String) -> String? {
        ///  Create a new encryption key in the photon-keyserver.
        ///   - Parameters:
        ///   - pin: pin String  A user chosen pin to authenticate to the keyserver
        ///   - completion: Result<String, Error> The key id for the encryption key
        var body: String?
        Alamofire.AF.request("baseUrl" + "/v2/key", method: .post, parameters: pin)
            .validate(statusCode: 201..<201)
            .responseString { response in
                    switch response.result {
                    case .success:
                        body = response.value
                    case let .failure(error):
                        print(error)
                    }
                }
        return body
    }
    
    func fetchKey(keyId: String) -> Data? {
        /// Download the encryption key from the key server. The pin needs to be set in the http auth headers before calling this method.
        /// - Parameters:
        ///   - keyId: The key id for the encryption key
        ///   - completion: The encryption key buffer
        var body: Data?
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)", method: .get)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                switch statusCode {
                case 200:
                    print("success")
                    body = response.data
                case 429:
                    print("Rate Limit Error")
                default:
                    print("Problem!")
                }
            }
        let decoder = JSONDecoder()
        let keyserverresponse = try! decoder.decode(KeyServerResponse.self, from: body!)
        return Data(base64Encoded: keyserverresponse.encryptionKey!)
    }

    func changePin(keyId: String, newPin: String) -> Void {
        /// Update the pin to a new one. The pin needs to be set in the http auth headers before calling this method.
        /// - Parameters:
        ///   - keyId: The key id for the encryption key
        ///   - newPin: The new pin to replace the old on
        ///   - completion: Success
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)", method: .put, parameters: newPin)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 429 {
                    print("rate limit error")
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
                self.setPin(pin: newPin)
            }
    }
    
    func createUser(keyId: String, userId: String) -> Void {
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user", method: .post, parameters: userId)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 429 {
                    print("rate limit error")
                }
                if statusCode != 201 {
                    print("Error requires handling")
                }
            }
    }

    func verifyUser(keyId: String, userId: String, code: String) -> Void {
        /// Verify the registered user id for a given key id.
        /// - Parameters:
        ///   - keyId: The key id for the encryption key
        ///   - userId: The user's phone number or email address
        ///   - code: The verification code sent via SMS or email
        ///   - completion: completion  Bool, Error
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let parameters: [String: String] = [
            "code": code,
            "op": "verify"
        ]
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)", method: .put, parameters: parameters)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 429 {
                    print("rate limit error")
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
    }

    func initPinReset(keyId: String, userId: String) -> Void {
        /// Initiate a pin reset in case the user forgot their pin. A time lock will be set in the keyserver.
        /// - Parameters:
        ///   - keyId: The key id for the encryption key
        ///   - userId: The user's phone number or email address
        ///   - completion: Result<Bool, Error
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)/reset", method: .get)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
    }
    
    func verifyPinReset(keyId: String, userId: String, code: String, newPin: String) -> String? {
        ///  Verify a pin reset. This api can be polled until the time lock delay is over and the http response status code is no longer 423. After this call is successful the new pin can be used to download the encryption key.
        /// - Parameters:
        ///   - keyId:   The key id for the encryption key
        ///   - userId: The user's phone number or email address
        ///   - code: The verification code sent via SMS or email
        ///   - newPin: The new pin to replace the old on
        ///   - completion: Delay , String
        var bodyData: Data?
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let parameters: [String: String] = [
            "code": code,
            "op": "reset-pin",
            "newPin": newPin
        ]
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)", method: .put, parameters: parameters)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 423 {
                    print("Error requires handling")
                    bodyData = response.data
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
        self.setPin(pin: newPin)
        
        let decoder = JSONDecoder()
        let keyserverresponse = try! decoder.decode(KeyServerResponse.self, from: bodyData!)
        return keyserverresponse.delay!
    }

    func removeUser(keyId:String, userId:String){
        /// Delete a user id from the key server. The pin needs to be set in the http auth
        /// - Parameters:
        ///   - keyId: The key id for the encryption key
        ///   - userId: The user's phone number or email address
        ///   - completion: Bool, Error
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)", method: .delete)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 429 {
                    print("Error requires handling")
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
    }

}
