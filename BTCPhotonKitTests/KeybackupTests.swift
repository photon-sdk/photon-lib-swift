//
//  Keybackup.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import XCTest
@testable import BTCPhotonKit

class KeybackupTests: XCTestCase {
    
    private var keyBackUp: Keybackup!
    private var cloudStore: CloudStore!
    let keyId = "8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f"
    let phone = "+4917512345678"
    let email = "jon.smith@example.com"
    let pin = "1234"
    let newPin = "5678"
    let ciphertext = Data(base64Encoded: "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==")
    let encryptionKeyBase64 = "95frn7hTHLDN7wsd2sG+FwMMLxNsx4ZgGlgPHHBejKI="
    let code = "000000"
    
    override func setUp() {
        keyBackUp = Keybackup("http://localhost:8000")
        cloudStore = CloudStore()
    }
    
    
    override func tearDown() {
        cloudStore = nil
    }
    
    
    func testCheckForExistingBackup(){
        XCTAssertFalse(keyBackUp.checkForExistingBackup(),"No backup should be found")
        XCTAssertNoThrow(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext))
        XCTAssertTrue(keyBackUp.checkForExistingBackup())
        XCTAssertEqual(cloudStore.getKey() as! String , keyId, "should set key id if exisiting item exists")
    }
    
    
    func testCreateBackup(){
        XCTAssertFalse( keyBackUp.checkForExistingBackup(),"No backup should be found")
        XCTAssertThrowsError(try keyBackUp.createBackup(data: nil, pin: ""), "This should fail as the data is invalid", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid data")
        })
        XCTAssertThrowsError(try keyBackUp.createBackup(data: Data(), pin: ""), "This should fail as the   pin is invalid", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid pin")
        })
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertTrue( keyBackUp.checkForExistingBackup(),"should encrypt and store the backup")
    }
    
    
    func testRestoreBackup(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertTrue( keyBackUp.checkForExistingBackup())
        XCTAssertEqual(try keyBackUp.restoreBackup(pin: pin),ciphertext,"should download and decrypt backup")
        XCTAssertFalse( keyBackUp.checkForExistingBackup(),"should return null if no backup found")
        XCTAssertThrowsError(try keyBackUp.restoreBackup(pin: pin), "should fail on invalid pin", { (error) in
        })
    }
    
    
    func testChangePin(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertThrowsError(try keyBackUp.changePin(pin: pin,newPin: ""), "should fail for invalid new pin", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid pin")
        })
        XCTAssertNoThrow (try keyBackUp.changePin(pin: pin,newPin: ""), "should update pin in key server")
    }
    
    
    func testRegisterPhone(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertThrowsError(try keyBackUp.registerPhone(userId: "", pin: pin) , "Invalid phone number", { (error) in
            XCTAssertEqual(error.localizedDescription,"A blank phone number is not valid")
        })
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin) , "This should set the phone number in the key server")
    }
    
    
    func testVerifyPhone(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertThrowsError(try keyBackUp.verifyPhone(userId: phone, code: "") , "should fail for invalid code", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid code")
        })
        XCTAssertNoThrow (try keyBackUp.verifyPhone(userId: phone, code: code)  , "should verify and store phone number in icloud")
        XCTAssertNotNil(keyBackUp.getPhone(),"should verify and store phone in icloud")
    }
    
    
    func testGetPhone(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertNil(keyBackUp.getPhone(),"should return null if the user has not been verified yet")
        XCTAssertNoThrow (try keyBackUp.verifyPhone(userId: phone, code: code))
        XCTAssertNotNil(keyBackUp.getPhone(),"should return verified phone number")
    }
    
    
    func testRemovePhone(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertNoThrow (try keyBackUp.verifyPhone(userId: phone, code: code))
        XCTAssertNoThrow (try keyBackUp.removePhone(userId: phone, pin: pin))
        XCTAssertNil(keyBackUp.getPhone(),"the phone number should have been deleted")
    }
    
    
    func testRegisterEmail(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertThrowsError(try keyBackUp.registerEmail(userId: "", pin: pin) , "should fail for invalid email address", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid email address")
        })
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin) , "should set phone in key server")
    }
    
    
    func testVerifyEmail(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        XCTAssertThrowsError(try keyBackUp.verifyEmail(userId: email, code: "") , "This should fail as the code is invalid", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid code provided")
        })
        XCTAssertNoThrow (try keyBackUp.verifyEmail(userId: email, code: code)  , "This should verify and store email address in icloud")
        XCTAssertNotNil(keyBackUp.getEmail(),"This should verify and store email address in icloud")
    }
    
    
    func testGetEmail(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        XCTAssertNil(keyBackUp.getEmail(),"should return null if user was not verified")
        XCTAssertNoThrow (try keyBackUp.verifyEmail(userId: email, code: code))
        XCTAssertNotNil(keyBackUp.getEmail(),"should return verified email")
    }

    
    func testRemoveEmail(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        XCTAssertNoThrow (try keyBackUp.verifyEmail(userId: email, code: code))
        XCTAssertNoThrow (try keyBackUp.removeEmail(userId: email, pin: pin))
        XCTAssertNil(keyBackUp.getEmail(),"This should be nil as the email should have been deleted")
    }
    
    
    func testInitPinReset(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertNoThrow (try keyBackUp.verifyPhone(userId: phone, code: code))
        XCTAssertThrowsError(try keyBackUp.registerPhone(userId: "", pin: pin) , "should fail for invalid user id", { (error) in
            XCTAssertEqual(error.localizedDescription,"Invalid phone")
        })
        XCTAssertNoThrow(try keyBackUp.initPinReset(userId: phone))
    }
    
    func testVerifyPinReset(){
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertNoThrow (try keyBackUp.verifyPhone(userId: phone, code: code))
        XCTAssertThrowsError(try keyBackUp.initPinReset(userId: phone))
        XCTAssertThrowsError(try keyBackUp.verifyPinReset(userId: phone, code: "", newPin: ""))
        XCTAssertThrowsError(try keyBackUp.verifyPinReset(userId: phone, code: code, newPin: ""))
        XCTAssertNoThrow(try keyBackUp.verifyPinReset(userId: phone, code: code, newPin: newPin))
        
    }
}
