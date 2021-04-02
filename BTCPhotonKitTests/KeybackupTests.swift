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
        // Given
        XCTAssertFalse(keyBackUp.checkForExistingBackup(),"No backup should be found")
        XCTAssertNoThrow(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext))
        
        // When
        XCTAssertTrue(keyBackUp.checkForExistingBackup())
        
        // Then
        XCTAssertEqual(cloudStore.getKey()?.keyId, keyId)
    }
        
    func testCreateBackup(){
        // Given
        XCTAssertThrowsError(try keyBackUp.createBackup(data: nil, pin: ""), "There is no data. This should throw.")
        XCTAssertThrowsError(try keyBackUp.createBackup(data: Data(), pin: ""), "There is no pin. This should throw.")
        XCTAssertThrowsError(try keyBackUp.createBackup(data: nil, pin: ""), "No parameters supplied, this should throw.")
        
        // When
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        
        // Then
        XCTAssertTrue(keyBackUp.checkForExistingBackup())
    }
    
    func testRestoreBackup(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertTrue(keyBackUp.checkForExistingBackup())
        
        // When
        XCTAssertNoThrow(try keyBackUp.restoreBackup(pin: pin))
                
        // Then
        XCTAssertFalse(keyBackUp.checkForExistingBackup(), "This should return false if no backup is found")
    }
    
    
    func testChangePin(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        
        // When
        XCTAssertThrowsError(try keyBackUp.changePin(pin: pin, newPin: ""), "The pin is invalid so this should fail.")
        
        // Then
        XCTAssertNoThrow (try keyBackUp.changePin(pin: pin, newPin: "4321"), "The pin is valid and should be updated on the key server")
    }
    
    
    func testRegisterPhone(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        
        // When
        XCTAssertThrowsError(try keyBackUp.registerPhone(userId: "", pin: pin) , "This should throw an error as the phone number is invalid.")
        
        // Then
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin) , "This should set the phone number in the key server")
    }
    
    
    func testVerifyPhone(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        
        // When
        XCTAssertThrowsError (try keyBackUp.registerPhone(userId: "", pin: pin), "This should fail as the phone number is missing")
        
        // Then
        XCTAssertThrowsError(try keyBackUp.VerifyPhone(userId: phone, code: ""), "This should fail as the code is invalid")
        XCTAssertNil(keyBackUp.getPhone(),"This should be nil as the previous attempt failed")
        XCTAssertNoThrow(try keyBackUp.VerifyPhone(userId: phone, code: code), "This should not fail as the phone and code is valid")
        XCTAssertNotNil(keyBackUp.getPhone(),"should verify and store phone in icloud")
    }
        
    func testGetPhone(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        XCTAssertNil(keyBackUp.getPhone(),"This should fail if the user has not been verified yet")
        
        // When
        XCTAssertNoThrow (try keyBackUp.VerifyPhone(userId: phone, code: code))
        
        // Then
        XCTAssertNotNil(keyBackUp.getPhone(),"This should return the verified phone number")
    }
    
    
    func testRemovePhone(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        
        // When
        XCTAssertNoThrow (try keyBackUp.VerifyPhone(userId: phone, code: code))
        XCTAssertNoThrow (try keyBackUp.removePhone(userId: phone, pin: pin))
        
        // Then
        XCTAssertNil(keyBackUp.getPhone(),"The phone number should have been deleted")
    }
    
    func testRegisterEmail(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        
        // When
        XCTAssertThrowsError(try keyBackUp.registerEmail(userId: "", pin: pin) , "This should fail as the email address is empty")
        
        // Then
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin) , "should set phone in key server")
    }
    
    func testVerifyEmail(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        
        // When
        XCTAssertThrowsError(try keyBackUp.VerifyEmail(userId: email, code: ""), "This should fail as the code is invalid")
        XCTAssertNoThrow (try keyBackUp.VerifyEmail(userId: email, code: code), "This should verify and store email address in icloud")
        
        // Then
        XCTAssertNotNil(keyBackUp.getEmail(),"This should verify and store email address in icloud")
    }
    
    func testGetEmail(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        
        // When
        XCTAssertNil(keyBackUp.getEmail(),"This should return nil as the user has not yet verified her email address")
        XCTAssertNoThrow (try keyBackUp.VerifyEmail(userId: email, code: code))
        
        // Then
        XCTAssertNotNil(keyBackUp.getEmail(),"should return verified email")
    }
    
    func testRemoveEmail(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerEmail(userId: email, pin: pin))
        
        // When
        XCTAssertNoThrow (try keyBackUp.VerifyEmail(userId: email, code: code))
        XCTAssertNoThrow (try keyBackUp.removeEmail(userId: email, pin: pin))
        
        // Then
        XCTAssertNil(keyBackUp.getEmail(),"This should be nil as the email should have been deleted")
    }
    
    
    func testInitPinReset(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        
        // When
        XCTAssertNoThrow (try keyBackUp.VerifyPhone(userId: phone, code: code))
        XCTAssertThrowsError(try keyBackUp.registerPhone(userId: "", pin: pin), "This should throw as the phone number is invalid")
        
        // Then
        XCTAssertNoThrow(try keyBackUp.initPinReset(userId: phone))
    }
    
    func testVerifyPinReset(){
        // Given
        XCTAssertNoThrow(try keyBackUp.createBackup(data: ciphertext, pin: pin))
        XCTAssertNoThrow (try keyBackUp.registerPhone(userId: phone, pin: pin))
        
        // When
        XCTAssertNoThrow (try keyBackUp.VerifyPhone(userId: phone, code: code))
        XCTAssertThrowsError(try keyBackUp.initPinReset(userId: phone))
        XCTAssertThrowsError(try keyBackUp.verifyPinReset(userId: phone, code: "", newPin: ""), "This should throw as the code and pin are empty")
        XCTAssertThrowsError(try keyBackUp.verifyPinReset(userId: phone, code: code, newPin: ""), "This should throw as the pin is empty")
        
        // Then
        XCTAssertNoThrow(try keyBackUp.verifyPinReset(userId: phone, code: code, newPin: newPin))
    }
}
