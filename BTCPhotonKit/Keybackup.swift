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
    let cloudStore = CloudStore()
    let keyserver = Keyserver("")
    var chacha = ChaCha()

    init(_ url:String) {
        baseUrl = URL(string: url)
    }
    
    public func checkForExistingBackup() -> Bool{
        // Check for an existing backup in cloud storage.
        // @return {<Bool>}
        let backup =  cloudStore.getKey()
        return backup != nil
    }
    
    func createBackup(data: Data?, pin: String ) throws {
        // This needs better error handling!
        
        //  Create an encrypted backup in cloud storage. The backup is encrypted using a
        // random 256 bit encryption key that is stored on the photon-keyserver. A user
        // chosen PIN is used to authenticate the downloading of the encryption key.
        // @param  {Data} data  A serializable object to be backed up
        // @param  {string} pin   A user chosen pin to authenticate to the keyserver
        // @return {<Void>}
        guard data != nil else {
            throw  GenericError(message: "Invalid data")
        }
        _ = setPin(pin: pin)
        let keyId = keyserver.createKey(pin: pin)
        let encryptionKey = keyserver.fetchKey(keyId: keyId!)
        let plaintext = Data()
        let ciphertext = try? chacha.encrypt(secret: plaintext, key: encryptionKey!)
        guard (ciphertext != nil) else {
            throw GenericError(message: "handle the error")
        }
        try cloudStore.putKey(keyId: keyId!, ciphertext: ciphertext)
    }

    
    func restoreBackup(pin:String)throws ->Data? {
        /**
         * Restore an encrypted backup from cloud storage. The encryption key is fetched from
         * the photon-keyserver by authenticating via a user chosen PIN.
         * @param  {string} pin       A user chosen pin to authenticate to the keyserver
         * @return {Data}  The decrypted backup payload
         */
        _ = setPin(pin: pin)
        let keyId = try fetchKeyId()
        let encryptionKey = keyserver.fetchKey(keyId: keyId)
        let backup = cloudStore.getKey()
        let ciphertext = Data(base64Encoded: "backup") // revisit this
        let plaintext = try! chacha.decrypt(cipher_bytes: ciphertext!, key: encryptionKey!)
        return plaintext
    }
    
    func changePin(pin:String, newPin:String) throws {
        guard Verify.isPin(newPin) else {
            throw GenericError(message: "Invalid pin")
        }
        _ = setPin(pin: pin)
        let keyId = try? fetchKeyId()
        keyserver.changePin(keyId: keyId!, newPin: newPin)
    }
    
    func registerPhone(userId: String, pin: String) throws {
        guard Verify.isPhone(userId) else {
            throw GenericError(message: "Invalid pin")
        }
        try? registerUser(userId: userId, pin: pin)
    }
    
    func VerifyPhone(userId: String, code: String) throws {
        guard Verify.isPhone(userId) &&  Verify.isCode(code) else {
            throw GenericError(message: "Invalid phone number")
        }
        try VerifyUser(userId: userId, code: code)
        try cloudStore.putPhone(userId: userId)
    }
    
    func getPhone() -> String? {
         // Get the phone number stored on the cloud storage which can be used to reset the pin.
         // @return {string}  The user's phone number
        return cloudStore.getPhone()
    }

    func removePhone(userId:String, pin:String)throws {
         // Delete the phone number from the key server and cloud storage. This should be called
         // before the user wants to change their user id to a new one.
         //  @param  {string} userId  The user's phone number
         // @param  {string} pin     A user chosen pin to authenticate to the keyserver
         // @return {Void}
        if (!Verify.isPhone(userId)) {
            throw  GenericError(message: "Invalid phone")
         }
        try removeUser(userId: userId, pin: pin)
        cloudStore.removePhone()
    }

    func registerEmail(userId:String, pin:String )throws {
        // Register an email address that can be used to reset the pin later in case the user
        // forgets pin. This step is completely optional and may not be desirable by some users
        // e.g. if they have saved their pin in a password manager.
        // @param  {string} userId  The user's email address
        // @param  {string} pin     A user chosen pin to authenticate to the keyserver
        // @return {Void}
        if (!Verify.isEmail(userId)) {
            throw  GenericError(message: "Invalid email")
        }
        try registerUser(userId: userId, pin: pin)
    }
    
    func VerifyEmail(userId:String, code:String )throws {
         // Verify the email address with a code that was sent from the keyserver either via email.
         // @param  {string} userId  The user's email address
         // @param  {string} code    The verification code sent via SMS or email
         // @return {Void}
        if (!Verify.isEmail(userId)) {
            throw  GenericError(message: "Invalid email")
         }
        if (!Verify.isCode(code)) {
            throw  GenericError(message: "Invalid code")
         }
        try VerifyUser(userId: userId, code: code)
        try cloudStore.putEmail(userId: userId)
    }

    func getEmail()->String {
         // Get the email address stored on the cloud storage which can be used to reset the pin.
         // @return {string}  The user's email address
        return cloudStore.getEmail()
    }
    
    func removeEmail(userId:String, pin:String )throws {
        /**
         * Delete the email address from the key server and cloud storage. This should be called
         * e.g. before the user wants to change their user id to a new one.
         * @param  {string} userId  The user's email address
         * @param  {string} pin     A user chosen pin to authenticate to the keyserver
         * @return {Void}
         */
        if (!Verify.isEmail(userId)) {
            throw  GenericError(message: "Invalid email")
         }
        try removeUser(userId: userId, pin: pin)
        cloudStore.removeEmail()
    }
    
    func registerUser(userId:String, pin:String ) throws {
        _ = setPin(pin: pin)
        let keyId = try fetchKeyId()
        keyserver.createUser(keyId: keyId, userId: userId)
    }
    
    func VerifyUser(userId:String, code:String ) throws {
        let keyId = try fetchKeyId()
        keyserver.verifyUser(keyId: keyId, userId: userId, code: code)
    }

    func removeUser(userId:String, pin:String) throws {
        _ = setPin(pin: pin)
        let keyId = try fetchKeyId()
        keyserver.removeUser(keyId: keyId, userId: userId)
    }

    // Reset PIN
    func initPinReset(userId: String) throws {
        /**
         * In case the user has forgotten their pin and has verified a user id like an
         * emaill address or phone number, this can be used to initiate a pin reset with
         * a 30 day delay (to migidate SIM swap attacks). After calling this function,
         * calling verifyPinReset will start the 30 day time lock. After that time delay
         * finalizePinReset can be called with the new pin.
         * @param  {string} userId       The user's phone number or email address
         * @return {.success}
         */
        guard Verify.isPhone(userId) && Verify.isEmail(userId) else {
            throw GenericError(message: "handle the error")
        }
        let keyId = try fetchKeyId()
        keyserver.initPinReset(keyId: keyId, userId: userId)
    }
    
    func verifyPinReset(userId:String, code:String, newPin:String) throws {
        /**
         * Verify the user id with a code and check if the time lock delay is over.
         * This function returns an iso formatted date string which represents the
         * time lock delay. If this value is null it means the delay is over and the
         * user can recover their key using the new pin.
         * @param  {string} userId         The user's phone number or email address
         * @param  {string} code           The verification code sent via SMS or email
         * @param  {string} newPin      The new pin (at least 4 digits)
         * @return {Result<Obj,Error>}  The time lock delay or null if it's over
         */
        guard Verify.isPhone(userId) && Verify.isEmail(userId) || !Verify.isCode(code) || !Verify.isPin(newPin) else {
            print("handle the error")
            throw GenericError(message: "handle the error")
        }
        let keyId = try fetchKeyId()
        keyserver.initPinReset(keyId: keyId, userId: userId)
    }
    
    // Helper functions
    func setPin(pin:String) -> Bool {
        if (!Verify.isPin(pin)) {
            return false
        }
        keyserver.setPin(pin: pin)
        return true
    }

    func fetchKeyId() throws -> String {
        let backup =  cloudStore.getKey()
        if ((backup == nil) || !Verify.isId(cloudStore.getKey() as! String)) {
            throw GenericError(message:"No key id found. Call checkForExistingBackup() first.")
          }
        return backup as! String
    }
}

struct GenericError: Error,LocalizedError {
    let message: String
    var errorDescription: String? {
        return message
    }
}

