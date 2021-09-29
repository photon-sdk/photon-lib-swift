//
//  Keyserver.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

// Manages all requests to the key server. Key tasks include getting, setting, and removing pins and users.
public class Keyserver {
    
    var client: NetworkingLayer = NetworkingLayer()// used for testing for now
    var baseUrl:String!
    var pin = ""
    public init(_ baseUrl:String) {
        self.baseUrl = baseUrl
    }

    var headerWithAuthentication:[String:Any]{
        // we have to swap user and password if needed according to server
        let loginString = String(format: "%@:%@", pin , "" )
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        return [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "Authorization":"Basic \(base64LoginString)"
        ]

    }

    /**
     * Set the user chosen PIN as a basic authentication http header.
     * @param {string} pin  A user chosen pin to authenticate to the keyserver
     */
    public func setPin(pin:String, completion: ((Result<String, Error>) -> Void)? = nil) {
        self.pin = pin
        completion?(.success(pin))
    }

//        NetWork.request(baseUrl,method: .post, body: ["pin":pin], responseType: KeyServerResponse.self)
//        { (result) in
//            if case .failure(let error) = result {
//                completion?(.failure(error))
//            }
//            if case .success(let data) = result{
//                if let id = data.id{
//                    completion?(.success(id))
//                }else{
//                    completion?(.failure(GenericError(message: data.message ?? "unknown error")))
//                }
//            }
//        }
//    }

    ///  Create a new encryption key in the photon-keyserver.
    ///   - Parameters:
    ///   - pin: pin String  A user chosen pin to authenticate to the keyserver
    ///   - completion: Result<String, Error> The key id for the encryption key
    
    public func createKey(pin:String,completion: @escaping(Result<String, Error>) -> Void) {
        let requestBody = try? NetworkBody(dictionary: ["pin":pin] )
        let request  = APIRequest(url:baseUrl,path: "/v2/key", method: .post, body: requestBody)
        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .failure(let error) = result {
                completion(.failure(error))
            }
            if case .success(let data) = result{
                if let id = data.id{
                    completion(.success(id))
                }else{
                    completion(.failure(GenericError(message: data.message ?? "unknown error")))
                }
            }
        }
    }
    
    /// Download the encryption key from the key server. The pin needs to be set in the http auth headers before calling this method.
    /// - Parameters:
    ///   - keyId: The key id for the encryption key
    ///   - completion: The encryption key buffer
    public func fetchKey(keyId:String, completion: @escaping(Result<Data, Error>) -> Void) {

        let request  = APIRequest(url:baseUrl,path: "/v2/key/\(keyId)", headers: headerWithAuthentication)
        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success(let data) = result{
                 if let encryptionKey = data.encryptionKey{
                    let data =  encryptionKey
                    completion(.success(data))
                }else{
                    completion(.failure(GenericError(message: data.message ?? "Something went wrong")))
                }
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if errorData.delay != nil{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }

    

    

    /// Update the pin to a new one. The pin needs to be set in the http auth headers before calling this method.
    /// - Parameters:
    ///   - keyId: The key id for the encryption key
    ///   - newPin: The new pin to replace the old on
    ///   - completion: Success
    public func changePin(keyId:String,newPin:String,completion: @escaping(Result<String, Error>) -> Void) {
        let requestBody = try? NetworkBody(dictionary: ["newPin":newPin])
        let request  = APIRequest(url:baseUrl,path: "/v2/key/\(keyId)", headers: headerWithAuthentication, body: requestBody)
        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                self.setPin(pin: newPin, completion: completion)
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if error.statusCode == 429{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }

    /// Register a new user id for a given key id. The pin needs to be set in the http auth headers before calling this method.
    /// - Parameters:
    ///   - keyId: he key id for the encryption key
    ///   - userId:  The user's phone number or email address
    ///   - completion: Success or error
    public func createUser(keyId:String, userId:String, completion: @escaping(Result<Bool, Error>) -> Void) {
        let requestBody = try? NetworkBody(dictionary: ["userId":userId] )
        let request  = APIRequest(url:baseUrl,path: "/v2/key/\(keyId)/user",
                                  method: .post,
                                  headers: headerWithAuthentication ,
                                  body: requestBody)

        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                completion(.success(true))
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if error.statusCode == 429{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }

    /// Verify the registered user id for a given key id.
    /// - Parameters:
    ///   - keyId: The key id for the encryption key
    ///   - userId: The user's phone number or email address
    ///   - code: The verification code sent via SMS or email
    ///   - completion: completion  Bool, Error
    
    public func verifyUser(keyId:String, userId:String, code:String, completion: @escaping(Result<Bool, Error>) -> Void) {
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let parameters: [String: String] = [
            "code": code,
            "op": "verify"
        ]
        let requestBody = try? NetworkBody(dictionary: parameters, encoding:.json )
        let request  = APIRequest(url:baseUrl,path: "/v2/key/\(keyId)/user/\(userId)", method: .post , body: requestBody)
        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                completion(.success(true))
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if error.statusCode == 429{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }

    /// Initiate a pin reset in case the user forgot their pin. A time lock will be set in the keyserver.
    /// - Parameters:
    ///   - keyId: The key id for the encryption key
    ///   - userId: The user's phone number or email address
    ///   - completion: Result<Bool, Error
    public func initPinReset(keyId:String, userId:String, completion: @escaping(Result<Bool, Error>) -> Void) {
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let request  = APIRequest(url:baseUrl, path: "/v2/key/\(keyId)/user/\(userId)/reset")
        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                completion(.success(true))
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                }else{
                    completion(.failure(error))
                }
            }
        }
    }


    ///  Verify a pin reset. This api can be polled until the time lock delay is over and the http response status code is no longer 423. After this call is successful the new pin can be used to download the encryption key.
    /// - Parameters:
    ///   - keyId:   The key id for the encryption key
    ///   - userId: The user's phone number or email address
    ///   - code: The verification code sent via SMS or email
    ///   - newPin: The new pin to replace the old on
    ///   - completion: Delay , String
    
    /**
     * Verify a pin reset. This api can be polled until the time lock delay is over and
     * the http response status code is no longer 423. After this call is successful the
     * new pin can be used to download the encryption key.
     * @param  {string} keyId          The key id for the encryption key
     * @param  {string} userId         The user's phone number or email address
     * @param  {string} code           The verification code sent via SMS or email
     * @param  {string} newPin         The new pin to replace the old on
     * @return {Promise<string|null>}  The time lock delay or null when it's over
     
    export async function verifyPinReset({ keyId, userId, code, newPin }) {
      userId = encodeURIComponent(userId);
      const { status, body } = await _api.put(`/v2/key/${keyId}/user/${userId}`, {
        body: { code, op: 'reset-pin', newPin },
      });
      if (status === 423) {
        return body.delay;
      }
      if (status !== 200) {
        throw new Error(`Keyserver error: ${body.message}`);
      }
      setPin({ pin: newPin });
      return null;
    }
     */
    
    public func verifyPinReset(keyId:String, userId:String,code:String,newPin:String, completion: @escaping(Result<String, Error>) -> Void) {
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let parameters: [String: String] = [
            "code": code,
            "op": "reset-pin",
            "newPin": newPin
        ]
        let requestBody = try? NetworkBody(dictionary:parameters)
        let request  = APIRequest(url:baseUrl,
                                  path: "/v2/key/\(keyId)/user/\(userId)",
                                  method: .put , body: requestBody)

        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                self.setPin(pin: newPin,completion:completion )
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if error.statusCode == 423{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }


    /// Delete a user id from the key server. The pin needs to be set in the http auth
    /// - Parameters:
    ///   - keyId: The key id for the encryption key
    ///   - userId: The user's phone number or email address
    ///   - completion: Bool, Error

    public func removeUser(keyId:String, userId:String,
                    completion: @escaping(Result<Bool, Error>) -> Void) {
        let userId = userId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let request  = APIRequest(url:baseUrl,path: "/v2/key/\(keyId)/user/\(userId)",
                                  method: .delete,
                                  headers: headerWithAuthentication)

        client.sendRequest(request: request, responseType: KeyServerResponse.self)
        { (result) in
            if case .success = result{
                completion(.success(true))
            }
            if case .failure(let error) = result {
                if let errorData:KeyServerResponse = error.errorResponse(){
                    if error.statusCode == 429{
                        completion(.failure(RateLimitError(message: "RateLimitError",delay: errorData.delay,statusCode: error.statusCode )))
                        return
                    }else{
                        completion(.failure(GenericError(message:errorData.message ?? error.localizedDescription)))
                        return
                    }
                }
                completion(.failure(error))
            }
        }
    }
}
