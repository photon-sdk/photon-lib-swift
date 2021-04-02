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
        /**
         Set the pin on the server.

         - Parameters:
            - pin:      A user chosen pin to authenticate to the keyserver
         - Returns:     Void
        */
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
        /**
         Create a new encryption key in the photon-keyserver.

         - Parameters:
            - pin:      A user chosen pin to authenticate to the keyserver
         - Returns:     The body of the network request as a string
        */
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
    
    func fetchKey(_ keyId: String) -> Data? {
        /**
         Fetch the encryption key from the key server.

         - Parameters:
            - keyId:        The key id for the encryption key
         - Returns:   The encryption key as a data object
        */
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

    func changePin(keyId: String, newPin: String) -> Error? {
        /**
         Change the pin to a new one.

         - Parameters:
            - keyId:    The key id for the encryption key
            - newPin:   The key id for the encryption key
         - Returns:     An optional error object
        */
        var pinError : Error?
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)", method: .put, parameters: newPin)
            .responseJSON { response in
                switch response.result {
                case .success:
                    print("success")
                    pinError = nil
                case let .failure(error):
                    pinError = error
                    let statusCode = response.response?.statusCode
                    if statusCode == 429 {
                        print("rate limit error")
                    }
                    if statusCode != 200 {
                        print("Error requires handling")
                    }
                }
                self.setPin(pin: newPin)
            }
        return pinError
    }
    
    func createUser(keyId: String, userId: String) -> Void {
        /**
         Create a new user id for a given key id.

         - Parameters:
            - keyId:    The key id for the encryption key
            - userId:   The user's phone number or email address
         - Returns:     Void
        */
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
        /**
         Verify the registered user id for a given key id.

         - Parameters:
            - keyId:    The key id for the encryption key
            - userId:   The user's phone number or email address
            - code:     The verification code sent via SMS or email
         - Returns:     Void
        */
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

    func initPinReset(keyId: String, userId: String) -> Error? {
        /**
         Initiate a pin reset in case the user forgot their pin. A time lock will be set in the keyserver.

         - Parameters:
            - keyId:    The key id for the encryption key
            - userId:   The user's phone number or email address
         - Returns:     An optional error
        */
        var resetError : Error? = nil
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)/reset", method: .get)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode != 200 {
                    print("Error requires handling")
                } else {
                    resetError = response.error
                }
            }
        return resetError
    }
    
    func verifyPinReset(keyId: String, userId: String, code: String, newPin: String) -> RateLimitError? {
        /**
         Verify a pin reset. This api can be polled until the time lock delay is over and the http response status code is no longer 423. After this call is successful the new pin can be used to download the encryption key.

         - Parameters:
            - keyId:    The key id for the encryption key
            - userId:   The user's phone number or email address
            - code:     The verification code sent via SMS or email
            - newPin:   The new pin to replace the old on
         - Returns:     An optional error
        */
        var pinError : RateLimitError? = nil
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
                    //pinError = response.error as RateLimitError
                    pinError = RateLimitError(message: "RateLimitError",delay: pinError?.delay,statusCode: pinError?.statusCode )
                    
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
        self.setPin(pin: newPin)
        //let decoder = JSONDecoder()
        //let keyserverresponse = try! decoder.decode(KeyServerResponse.self, from: bodyData!)
        //return keyserverresponse.delay!
        return pinError
    }

    func removeUser(keyId:String, userId:String) -> Error? {
        /**
         Delete a user id from the key server.

         - Parameters:
            - keyId:    The key id for the encryption key
            - userId:   The user's phone number or email address
         - Returns:     An optional error
        */
        var pinError : Error? = nil
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        Alamofire.AF.request(baseUrl + "/v2/key/\(keyId)/user/\(userId)", method: .delete)
            .responseJSON { response in
                let statusCode = response.response?.statusCode
                if statusCode == 429 {
                    print("Error requires handling")
                    pinError = response.error
                }
                if statusCode != 200 {
                    print("Error requires handling")
                }
            }
        
        return pinError
    }

}
