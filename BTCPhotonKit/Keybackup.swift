//
//  Keybackup.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

public class Keybackup {
    // Handles the backup and restoration of the seed.
    let baseUrl:URL?
    let cloudStore:CloudStore
    let keyserver:Keyserver
    var chacha = ChaCha()

    public init(_ url:String, cloudStore:CloudStore = CloudStore()) {
        baseUrl = URL(string: url)
        self.cloudStore  = cloudStore
        keyserver   = Keyserver(url)
    }
    
    public func checkForExistingBackup( completion: @escaping(Result<Bool, Error>) -> Void){
        /**
         Check for an existing backup in cloud storage. Returns Bool.

         - Returns: Bool, depending on whether an existing backup exists.
        */
        self.cloudStore.getKey(){
                    result in
                    if case .success = result {
                        completion(.success(true))
                    }
                    if case .failure(let error) = result {
                        completion(.failure(error))
                    }
                }
            }
    
    public func createBackup(data: Data?, pin: String, completion: @escaping(Result<Bool, Error>) -> Void ) {
        /**
         Create an encrypted backup in cloud storage. The backup is encrypted using a random 256 bit encryption key that is stored on the photon-keyserver. A user chosen PIN is used to authenticate the downloading of the encryption key.

         - Parameters:
            - data: A serializable object to be backed up
            - pin:  A user chosen pin to authenticate to the keyserver
         - Returns: None
        */
        guard let data = data else {
                completion(.failure(GenericError(message: "Invalid data")))
                return
            }
        guard setPin(pin: pin) else{
                completion(.failure(GenericError(message: "Invalid pin")))
                return
            }
            keyserver.createKey(pin: pin) { result in
                if case .success(let keyId) = result {
                    self.keyserver.fetchKey(keyId: keyId) { (resultKey) in
                        if case .failure(let error) = resultKey {
                            completion(.failure(error))
                        }
                        if case .success(let key ) = resultKey {

                            let ciphertext = try? self.chacha.encrypt(secret:data , key: key )
                            guard (ciphertext != nil) else {
                                completion(.failure(GenericError(message: "handle the error")))
                                return
                            }
                            self.cloudStore.putKey(keyId: keyId, ciphertext: ciphertext, completion: completion)
                        }
                    }
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }
    }
    
    /**
     Restore an encrypted backup from cloud storage. The encryption key is fetched from the photon-keyserver by authenticating via a user chosen PIN.

     - Parameters:
        - pin: A user chosen pin to authenticate to the keyserver
     - Returns: The decrypted backup payload
    */
    public func restoreBackup(pin:String, completion: @escaping
                            (Result<Data?, Error>) -> Void){
            guard setPin(pin: pin) else{
                completion(.failure(GenericError(message: "Invalid pin")))
                return
            }
            fetchKeyId(){
                result in
                if case .success(let data) = result {
                    self.keyserver.fetchKey(keyId: data) { (result) in
                        if case .success(let encryptionKey) = result {
                            self.cloudStore.getKey(){
                                result in
                                if case .success(let data) = result {
                                    do {
                                        if let ciphertext =  data.ciphertext {
                                             // revisit this
                                            let plaintext = try self.chacha.decrypt(cipher_bytes: ciphertext , key: encryptionKey)
                                        completion(.success(plaintext))
                                        }else{
                                            completion(.failure(GenericError(message: "parse Error")))
                                        }
                                    } catch {
                                        completion(.failure(error))
                                    }

                                }
                                if case .failure(let error) = result {
                                    completion(.failure(error))
                                }

                            }

                        }
                        if case .failure(let error) = result {
                            completion(.failure(error))
                        }

                    }
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }

        }
    

    /**
     Change the users chosen PIN on the photon-keyserver.

     - Parameters:
        - pin:      The users old pin
        - newPin:   A new pin chosen by the user
     - Returns:     None
    */
    public func changePin(pin:String, newPin:String, completion: @escaping(Result<String, Error>) -> Void ){
            guard setPin(pin: newPin) else{
                completion(.failure(GenericError(message: "Invalid pin")))
                return
            }
            fetchKeyId(){
                result in

                if case .success(let keyId) = result {
                    self.keyserver.changePin(keyId: keyId,
                                             newPin: newPin,
                                             completion:completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }

        }
    
    /**
     Register a phone number that can be used to reset the pin later in case she forgets it.
     This step is completely optional and may not be desirable by some users e.g. if they have saved their pin in a password manager.

     - Parameters:
        - userId:   The user's email address
        - pin:      A user chosen pin to authenticate to the keyserver
     - Throws:      Yes
    */
    public func registerPhone(userId: String, pin: String, completion: @escaping(Result<Bool, Error>) -> Void) {
            guard Verify.isPhone(userId) else {
                completion(.failure(GenericError(message: "Invalid pin")))
                return
            }
            registerUser(userId: userId, pin: pin, completion: completion);
        }
    
    /**
     Verify the phone number with a code that was sent from the keyserver either via SMS.

     - Parameters:
        - userId:   The user's email address
        - pin:      A user chosen pin to authenticate to the keyserver
     - Throws:      Yes
    */
    
    public func verifyPhone(userId: String, code: String, completion: @escaping(Result<Bool, Error>) -> Void) {
            guard Verify.isPhone(userId) &&  Verify.isCode(code) else {
                completion(.failure(GenericError(message: "Invalid phone number")))
                return
            }
            verifyUser(userId: userId, code: code){
                result in
                if case .success = result {
                    self.cloudStore.putPhone(userId: userId){
                        result in
                        if case .success = result {
                            completion(.success(true))
                        }
                        if case .failure(let error) = result {
                            completion(.failure(error))
                        }
                    }
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }

        }
    
    
    /**
     Get the phone number stored on the cloud storage which can be used to reset the pin.

     - Parameters:
        - secret:           The data being encrypted
        - key:              the key needed to decrypt the data
     - Returns:             The user's phone number as a string
    */
    public func getPhone(completion: @escaping(Result<String?, CloudstoreError>) -> Void){
          return cloudStore.getPhone(completion:completion );
        }
    
    
    /**
     Delete the phone number from the key server and cloud storage. This should be called before the user wants to change their user id to a new one.

     - Parameters:
        - userId:   The user's phone number
        - pin:      A user chosen pin to authenticate to the keyserver
     - Returns:     None
    */
    public func removePhone(userId:String, pin:String, completion: @escaping(Result<Bool, Error>) -> Void ){
            if (!Verify.isPhone(userId)) {
                completion(.failure(GenericError(message:"Invalid phone")))
                return
            }
            removeUser(userId: userId, pin: pin){
                result in
                if case .success = result {
                    self.cloudStore.removePhone(completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }

        }
    
    
    /**
     Register an email address that can be used to reset the pin later in case the user forgets pin. This step is completely optional and may not be desirable by some users. e.g. if they have saved their pin in a password manager.

     - Parameters:
        - userId:   The user's email address
        - pin:      A user chosen pin to authenticate to the keyserver
     - Returns:     None
    */
    public func registerEmail(userId:String, pin:String, completion: @escaping(Result<Bool, Error>) -> Void ){
            if (!Verify.isEmail(userId)) {
                completion(.failure(GenericError(message: "Invalid email")))
                return
            }
            registerUser(userId: userId, pin: pin, completion: completion )
        }
    
    
    /**
     Verify the email address with a code that was sent from the keyserver either via email.

     - Parameters:
        - userId:   The user's email address
        - code:     The verification code sent via SMS or email
     - Returns:     None
    */
    public func verifyEmail(userId:String, code:String,
                         completion: @escaping(Result<Bool, Error>) -> Void) {
            if (!Verify.isEmail(userId)) {
                completion(.failure(GenericError(message: "Invalid email")))
            }
            if (!Verify.isCode(code)) {
                completion(.failure(GenericError(message: "Invalid code")))
            }
            verifyUser(userId: userId, code: code){
                result in
                if case .success = result {
                    self.cloudStore.putEmail(userId: userId){
                        result in

                        if case .success = result {
                            completion(.success(true))
                        }
                        if case .failure(let error) = result {
                            completion(.failure(error))
                        }
                    }
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }
        }
    
    /**
     Get the email address stored on the cloud storage which can be used to reset the pin.
     - Returns: The user's email address
    */
    public func getEmail(completion: @escaping(Result<String, CloudstoreError>) -> Void){
            return cloudStore.getEmail(completion:completion);
        }
    
    
    /**
     Delete the email address from the key server and cloud storage.
     This should be called before the user wants to change their user id to a new one.

     - Parameters:
        - userId:   The user's email address
        - pin:      A user chosen pin to authenticate to the keyserver
     - Throws:      Yes
    */
    public func removeEmail(userId:String, pin:String,
                         completion: @escaping(Result<Bool, Error>) -> Void){
            /**
             * Delete the email address from the key server and cloud storage. This should be called
             * e.g. before the user wants to change their user id to a new one.
             * @param  {string} userId  The user's email address
             * @param  {string} pin     A user chosen pin to authenticate to the keyserver
             * @return {Void}
             */
            if (!Verify.isEmail(userId)) {
                completion(.failure(GenericError(message: "Invalid email")))
            }
            removeUser(userId: userId, pin: pin){
                result in
                if case .success = result {
                    self.cloudStore.removeEmail(completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }
        }
    
    
    /**
     Register the user on the photon server.

     - Parameters:
        - userId:           Used to identify the user that needs to be removed
        - pin:              The pin needed to authenticate the request
     - Throws:              Yes
    */
    public func registerUser(userId:String, pin:String, completion: @escaping(Result<Bool, Error>) -> Void) {
            _ = setPin(pin: pin)
            fetchKeyId(){
                result in
                if case .success(let keyId) = result {
                    self.keyserver.createUser(keyId: keyId, userId: userId,completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }

        }
    
    
    /**
     Verify the user on the photon server

     - Parameters:
        - userId:           Used to identify the user that needs to be removed
        - code:             The code received to verify this is the correct user
     - Throws:              Yes
    */
    public func verifyUser(userId:String, code:String, completion: @escaping(Result<Bool, Error>) -> Void ) {
            fetchKeyId(){
                result  in
                if case .success(let keyId) = result {
                    self.keyserver.verifyUser(keyId: keyId, userId: userId, code: code, completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }
        }
    
    
    /**
     Remove the user from the keyserver

     - Parameters:
        - userId:           Used to identify the user that needs to be removed
        - pin:              the pin needed to authenticate the request
     - Throws:              Yes
    */
    public func removeUser(userId:String, pin:String, completion: @escaping(Result<Bool, Error>) -> Void ) {
            guard setPin(pin: pin) else{
                completion(.failure(GenericError(message: "Invalid pin")))
                return
            }
            fetchKeyId(){
                result  in
                if case .success(let keyId) = result {
                    self.keyserver.removeUser(keyId: keyId,
                                              userId: userId,
                                              completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }
            }

        }
    
    
    /**
     In case the user has forgotten their pin and has verified a user id like an emaill address or phone number, this can be used to initiate a pin reset with a 30 day delay (to migidate SIM swap attacks). After calling this function, calling verifyPinReset will start the 30 day time lock. After that time delay finalizePinReset can be called with the new pin.

     - Parameters:
        - userId:   The user's phone number or email address
        - code:     The verification code sent via SMS or email
     - Returns: None
    */
    // Reset PIN
    func initPinReset(userId: String, completion: @escaping(Result<Bool, Error>) -> Void ) {
            guard Verify.isPhone(userId) || Verify.isEmail(userId) else {
                completion(.failure(GenericError(message: "Invalid userId")))
                return
            }
            fetchKeyId(){
                result in
                if case .success(let keyId) = result {
                    self.keyserver.initPinReset(keyId: keyId, userId: userId,completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }

        }
    
    /**
     Verify the user id with a code and check if the time lock delay is over. This function returns an iso formatted date string which represents the time lock delay. If this value is null it means the delay is over and the user can recover their key using the new pin.

     - Parameters:
        - userId:   The user's phone number or email address
        - code:     The verification code sent via SMS or email
        - newPin:   The new pin (at least 4 digits)
     - Returns: None
    */
    func verifyPinReset(userId:String, code:String, newPin:String, completion: @escaping(Result<Bool, Error>) -> Void ) {
            guard (Verify.isPhone(userId) || Verify.isEmail(userId)) && Verify.isCode(code) && Verify.isPin(newPin) else {
                print("handle the error")
                completion(.failure(GenericError(message: "Invalid userId , code or newPin")))
                return
            }
            fetchKeyId(){
                result in
                if case .success(let keyId) = result {
                    self.keyserver.initPinReset(keyId: keyId,
                                                userId: userId,
                                                completion: completion)
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }

        }
    
    /**
     Set the users pin to the provided number.

     - Parameters:
        - pin:      The new pin (at least 4 digits)
     - Returns:     True if the pin is a number, false otherwise
    */
    func setPin(pin: String) -> Bool {
            if (!Verify.isPin(pin)) {
                return false
            }
            keyserver.setPin(pin: pin)
            return true
        }
    
    /**
     Fetch the keyid stored in iCloud
     
     - Throws:      True
     - Returns:     The keyid as a string
    */
    func fetchKeyId(completion:@escaping (Result<String,Error>) -> Void){
        cloudStore.getKey(){
            result in
            if case .success(let data) = result {
                guard Verify.isId(data.keyId) else{
                    completion(.failure(GenericError(message:"Invalid key id")))
                    return
                }
                completion(.success(data.keyId))
            }
            if case .failure(let error) = result {
                completion(.failure(error))
            }
        }
    }
}
struct GenericError: Error,LocalizedError {
    let message: String
    var errorDescription: String? {
        return message
    }
}
