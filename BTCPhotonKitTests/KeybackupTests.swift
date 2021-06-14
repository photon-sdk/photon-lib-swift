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
    let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
    let encryptionKeyBase64 = "95frn7hTHLDN7wsd2sG+FwMMLxNsx4ZgGlgPHHBejKI="
    let code = "000000"

    override func setUp() {
        cloudStore = CloudStore(store: MockCloudDAO())
        keyBackUp = Keybackup("http://localhost:8000", cloudStore: cloudStore)
    }

    override func tearDown() {
        cloudStore = nil
    }

    func updateSession(response:String){
        let session = MockURLSession(
            data: response.data(using: .ascii),
            urlResponse: nil,
            error: nil)
        // updating the networking layer with mock session
        keyBackUp.keyserver.client = NetworkingLayer(session: session)
        cloudStore.store.clear()
    }

    func testCheckForExistingBackup(){
        cloudStore.store.clear()

        // Given
        let backupExpectation = expectation(description: "Error: Data is invalid")
        var createBackupResponse: String? // Holds  response need to check on expectation

        // When
        keyBackUp.checkForExistingBackup{
            result in
            if case .success = result {
                backupExpectation.fulfill()
            }
            if case .failure = result {
                self.cloudStore.putKey(keyId: keyId, ciphertext: ciphertext){
                    result in

                    if case .success = result{
                        self.keyBackUp.checkForExistingBackup{
                            result in
                            if case .success = result{

                                self.cloudStore.getKey{
                                    result in

                                    if case .success(let data) = result {
                                        createBackupResponse = data.keyId
                                    }
                                        backupExpectation.fulfill()
                                }
                            }else{
                                backupExpectation.fulfill()
                            }
                        }
                    }else{
                        backupExpectation.fulfill()
                    }
                }
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill to avoid the order of execution issues
            // To avoid the worst case we're adding a timeout of 1
            XCTAssertNotNil(createBackupResponse, "should fail on invalid data")
            XCTAssertTrue(createBackupResponse?.contains(keyId) == true,"should contain key in it")
        }

    }

    func testCreateBackupWithNilData(){

        // Given
        cloudStore.store.clear()
        let createBackupExpectation = expectation(description: "Error: Data is invalid") // expectation to handle the async task
        var createBackupResponse: Bool? // holds response need to check on expectation

        // When
        keyBackUp.createBackup(data: nil, pin: ""){ result in
            if case .success(let data) = result {
                // if our session will return an error
                // this will not set
                createBackupResponse = data
            }
            createBackupExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case we re adding a timeout of 1
            XCTAssertNil(createBackupResponse, "should fail on invalid data")
        }
    }

    func testCreateBackupWithNilPin(){
        cloudStore.store.clear()

        // Given
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let createBackupExpectation = expectation(description: "Invalid pin")// expectation to handle the async task
        var createBackupResponse: Bool?// holds response need to check on expectation

        // When
        keyBackUp.createBackup(data: ciphertext, pin: ""){ result in
            if case .success(let data) = result {
                // if our session will return an error
                // this will not set
                createBackupResponse = data
            }
            createBackupExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case we re adding a timeout of 1
            XCTAssertNil(createBackupResponse, "should fail on invalid pin")
        }
    }

    func testCreateBackup(){

        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        // expectation to handle the async task
        let createBackupExpectation = expectation(description: "Invalid pin")
        // Holds  response need to check on expectation
        var createBackupResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success(let data) = result {
                // if our session will return an error
                // this will not set
                createBackupResponse = data
            }
            createBackupExpectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case we re adding a timeout of 1
            XCTAssertTrue((createBackupResponse == true), "Successful creation of backup")
           }

    }
    
    
    func testRestoreBackup(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let restoreBackupExpectation = expectation(description: "Backup restored")
        // Holds  response need to check on expectation
        var restoreBackupResponse: Data?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.restoreBackup(pin: pin){ result in
                    if case .success(let data) = result {
                        restoreBackupResponse = data
                    }
                    restoreBackupExpectation.fulfill()
                }
            }else{
                restoreBackupExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case we re adding a timeout of 1
            XCTAssertNotNil( restoreBackupResponse, "should download and decrypt backup")
        }
    }

    func testChangePinError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let changePinExpectation = expectation(description: "Invalid pin error")
        // Holds  response need to check on expectation
        var changePinResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.changePin(pin: pin, newPin: ""){ result in
                    if case .success(let data) = result {
                        changePinResponse = data
                    }
                    changePinExpectation.fulfill()
                }
            }else{
                changePinExpectation.fulfill()
            }
        }
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( changePinResponse, "Invalid pin error")
        }
    }

    func testChangePin(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let newPin = "5678"
        let changePinExpectation = expectation(description: "Expecting a changed pin")
        // Holds  response need to check on expectation
        var changePinResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                 self.keyBackUp.changePin(pin: pin, newPin: newPin){ result in
                    if case .success(let data) = result {
                        changePinResponse = data
                    }
                    changePinExpectation.fulfill()
                }
            }else{
                changePinExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( changePinResponse, "should change for invalid new pin")
        }
    }

    func testRegisterPhoneError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let registerPhoneExpectation = expectation(description: "Invalid pin error")
        // Holds  response need to check on expectation
        var registerPhoneResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                 self.keyBackUp.registerPhone(userId: "", pin: pin){ result in
                    if case .success(let data) = result {
                        registerPhoneResponse = data
                    }
                    registerPhoneExpectation.fulfill()
                }
            }else{
                registerPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( registerPhoneResponse, "A blank phone number is not valid")
        }
    }

    func testRegisterPhone(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let registerPhoneExpectation = expectation(description: "Successful registration of phone number")
        // Holds  response need to check on expectation
        var registerPhoneResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success(let data) = result {
                        registerPhoneResponse = data
                    }
                    registerPhoneExpectation.fulfill()
                }
            }else{
                registerPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( registerPhoneResponse, "should set the phone number in the key server")
        }
    }

    func testVerifyPhoneError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let verifyPhoneExpectation = expectation(description: "Wrong pin")
        // Holds  response need to check on expectation
        var verifyPhoneResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: ""){ result in
                            if case .success(let data) = result {
                                verifyPhoneResponse = data
                            }
                            verifyPhoneExpectation.fulfill()
                        }
                    }else{
                        verifyPhoneExpectation.fulfill()
                    }
                }
            }else{
                verifyPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( verifyPhoneResponse,
                          "should fail for invalid code")
        }
    }

    func testVerifyPhone(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let code = "000000"
        let verifyPhoneExpectation = expectation(description: "Phone not verified")
        // Holds  response need to check on expectation
        var verifyPhoneResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code){ result in
                            if case .success(let data) = result {
                                verifyPhoneResponse = data
                            }
                            verifyPhoneExpectation.fulfill()
                        }
                    }else{
                        verifyPhoneExpectation.fulfill()
                    }
                }
            }else{
                verifyPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( verifyPhoneResponse, "should verify and store phone number in icloud")
        }
    }

    func testGetPhoneError(){

        // Given
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let verifyPhoneExpectation = expectation(description: "Phone number not verified")
        // Holds  response need to check on expectation
        var verifyPhoneResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.getEmail{
                            result in
                            if case .success(let data) = result {
                                verifyPhoneResponse = data
                            }
                            verifyPhoneExpectation.fulfill()
                        }
                    }else{
                        verifyPhoneExpectation.fulfill()
                    }
                    verifyPhoneExpectation.fulfill()
                }
            }else{
                verifyPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil(verifyPhoneResponse, "should return null if the user has not been verified yet")
         }
    }


    func testGetPhone(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let code = "000000"
        let verifyPhoneExpectation = expectation(description: "Got phone number")
        // Holds  response need to check on expectation
        var verifyPhoneResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.getPhone{
                                    result in
                                    if case .success(let data) = result {
                                        verifyPhoneResponse = data
                                    }
                                    verifyPhoneExpectation.fulfill()
                                }
                            }else{
                                verifyPhoneExpectation.fulfill()
                            }
                        }
                    }else{
                        verifyPhoneExpectation.fulfill()
                    }
                }
            }else{
                verifyPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( verifyPhoneResponse, "should retrieve phone number from icloud")
         }
    }

    func testRemovePhone(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let code = "000000"
        let verifyPhoneExpectation = expectation(description: "Phone number removed")
        // Holds  response need to check on expectation
        var verifyPhoneResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.removePhone(userId: phone, pin: pin)
                                { result in

                                    if case .success(let data) = result {
                                        verifyPhoneResponse = data
                                    }
                                    verifyPhoneExpectation.fulfill()
                                }

                            }else{
                                verifyPhoneExpectation.fulfill()
                            }
                        }
                    }else{
                        verifyPhoneExpectation.fulfill()
                    }
                }
            }else{
                verifyPhoneExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( verifyPhoneResponse, "phone number removed")
        }
    }

    func testRegisterEmailError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let emailExpectation = expectation(description: "email registration failed")
        // Holds  response need to check on expectation
        var emailResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                 self.keyBackUp.registerEmail(userId: "", pin: pin){ result in
                    if case .success(let data) = result {
                        emailResponse = data
                    }
                    emailExpectation.fulfill()
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case we re adding a timeout of 1
            XCTAssertNil(emailResponse, "A blank phone number is not valid")
        }
    }

    func testRegisterEmail(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let pin = "1234"
        let email = "jon.smith@example.com"
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let emailExpectation = expectation(description: "registration success")
        // Holds  response need to check on expectation
        var emailResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                 self.keyBackUp.registerEmail(userId: email, pin: pin){ result in
                    if case .success(let data) = result {
                        emailResponse = data
                    }
                    emailExpectation.fulfill()
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( emailResponse, "should set the phone number in the key server")
        }
    }

    func testVerifyEmailError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let email = "jon.smith@example.com"
        let emailExpectation = expectation(description: "email verification error")
        // Holds  response need to check on expectation
        var emailResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerEmail(userId: email, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.verifyEmail(userId: email, code: ""){ result in
                            if case .success(let data) = result {
                                emailResponse = data
                            }
                            emailExpectation.fulfill()
                        }
                    }else{
                        emailExpectation.fulfill()
                    }
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( emailResponse, "should fail for invalid code")
        }
    }

    func testVerifyEmail(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let email = "jon.smith@example.com"
        let code = "000000"
        let emailExpectation = expectation(description: "Expecting email verification")
        // Holds  response need to check on expectation
        var emailResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerEmail(userId: email, pin: pin)
                { result in
                    if case .success = result {
                        self.keyBackUp.verifyEmail(userId: email, code: code)
                        { result in
                            if case .success(let data) = result {
                                emailResponse = data
                            }
                            emailExpectation.fulfill()
                        }
                    }else{
                        emailExpectation.fulfill()
                    }
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( emailResponse,
                             "should verify and store phone number in icloud")
        }
    }

    func testGetEmailError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let email = "jon.smith@example.com"
        let emailExpectation = expectation(description: "Expecting to failed with verify Error")
        // Holds  response need to check on expectation
        var emailResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerEmail(userId: email, pin: pin){ result in
                    if case .success = result {
                        self.keyBackUp.getEmail{
                            result in
                            if case .success(let data) = result {
                                emailResponse = data
                            }
                            emailExpectation.fulfill()
                        }

                    }else{
                        emailExpectation.fulfill()
                    }
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil(emailResponse, "should return null if the user has not been verified yet")
         }
    }


    func testGetEmail(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let email = "jon.smith@example.com"
        let code = "000000"
        let emailExpectation = expectation(description: "Retrieved email")
        // Holds  response need to check on expectation
        var emailResponse: String?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                 self.keyBackUp.registerEmail(userId: email, pin: pin)
                 { result in
                    if case .success = result {
                        self.keyBackUp.verifyEmail(userId: email, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.getEmail{
                                    result in
                                    if case .success(let data) = result {
                                        emailResponse = data
                                    }
                                    emailExpectation.fulfill()
                                }
                            }else{
                            emailExpectation.fulfill()
                            }
                        }
                    }else{
                        emailExpectation.fulfill()
                    }
                }
            }else{
                emailExpectation.fulfill()
            }
        }
        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( emailResponse, "should verify and store phone number in icloud")
        }
    }

    func testRemoveEmail(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let email = "jon.smith@example.com"
        let code = "000000"
        let emailExpectation = expectation(description: "Remove email")
        // Holds  response need to check on expectation
        var emailResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerEmail(userId: email, pin: pin)
                { result in
                    if case .success = result {
                        self.keyBackUp.verifyEmail(userId: email, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.removeEmail(userId: email, pin: pin)
                                { result in

                                    if case .success(let data) = result {
                                        emailResponse = data
                                    }
                                    emailExpectation.fulfill()
                                }

                            }else{
                                emailExpectation.fulfill()
                            }
                        }
                    }else{
                        emailExpectation.fulfill()
                    }
                }
            }else{
                emailExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil(emailResponse, "got email")
         }
    }

    func testInitPinReset(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let code = "000000"
        let pinExpectation = expectation(description: "Pin reset")
        // Holds  response need to check on expectation
        var pinResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin)
        { result in
            if case .success = result {
               self.keyBackUp.registerPhone(userId: phone, pin: pin)
               { result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.initPinReset(userId: phone )
                                { result in

                                    if case .success(let data) = result {
                                        pinResponse = data
                                    }
                                    pinExpectation.fulfill()
                                }

                            }else{
                                pinExpectation.fulfill()
                            }
                        }
                    }else{
                        pinExpectation.fulfill()
                    }
                }
            }else{
                pinExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( pinResponse, "pin reset success")

        }
    }

    func testVerifyPinResetError(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let newPin = "5678"
        let phone = "+4917512345678"
        let code = "000000"
        let pinExpectation = expectation(description: "Pin reset error")
        // Holds  response need to check on expectation
        var pinResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin)
                { result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.initPinReset(userId: phone )
                                { result in

                                    if case .success = result {
                                        self.keyBackUp.verifyPinReset(
                                            userId: phone,
                                            code: "",
                                            newPin: newPin){
                                            result in
                                            if case .success(let data) = result {
                                                pinResponse = data
                                            }
                                            pinExpectation.fulfill()
                                        }

                                    }else{
                                        pinExpectation.fulfill()
                                    }
                                }

                            }else{
                                pinExpectation.fulfill()
                            }
                        }
                    }else{
                        pinExpectation.fulfill()
                    }
                }
            }else{
                pinExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( pinResponse, "error Code")

        }
    }

    func testVerifyPinResetErrorPin(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let pin = "1234"
        let phone = "+4917512345678"
        let code = "000000"
        let pinExpectation = expectation(description: "Pin reset error")
        // Holds  response need to check on expectation
        var pinResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin)
                { result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.initPinReset(userId: phone)
                                { result in

                                    if case .success = result {

                                        self.keyBackUp.verifyPinReset(
                                            userId: phone,
                                            code: code,
                                            newPin: ""){
                                            result in
                                            if case .success(let data) = result {
                                                pinResponse = data
                                            }
                                            pinExpectation.fulfill()
                                        }

                                    }else{
                                        pinExpectation.fulfill()
                                    }
                                }

                            }else{
                                pinExpectation.fulfill()
                            }
                        }
                    }else{
                        pinExpectation.fulfill()
                    }
                }
            }else{
                pinExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNil( pinResponse, "error pin")

        }
    }


    func testVerifyPinReset(){
        // Given
        updateSession(response: "{ \"id\": \"8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f\", \"encryptionKey\": \"jNEwxbmdFh8uVuNOX4MKS/adqEIAUihPKK1L4Higz2A=\" }")
        let ciphertext = "sNz6ocyiJsIhC/48RhXdqZZyxQ/sFigpDbEpHE8UnSb2XxeIfCxB8Q==".data(using: .utf8)
        let phone = "+4917512345678"
        let pin = "1234"
        let newPin = "5678"
        let code = "000000"
        let pinExpectation = expectation(description: "Pin reset verified")
        // Holds  response need to check on expectation
        var pinResponse: Bool?

        // When
        keyBackUp.createBackup(data: ciphertext, pin: pin){ result in
            if case .success = result {
                self.keyBackUp.registerPhone(userId: phone, pin: pin)
                { result in
                    if case .success = result {
                        self.keyBackUp.verifyPhone(userId: phone, code: code)
                        { result in
                            if case .success = result {
                                self.keyBackUp.initPinReset(userId: phone)
                                { result in

                                    if case .success = result {

                                        self.keyBackUp.verifyPinReset(
                                            userId: phone,
                                            code: code,
                                            newPin: newPin){
                                            result in
                                            if case .success(let data) = result {
                                                pinResponse = data
                                            }
                                            pinExpectation.fulfill()
                                        }

                                    }else{
                                        pinExpectation.fulfill()
                                    }
                                }

                            }else{
                                pinExpectation.fulfill()
                            }
                        }
                    }else{
                        pinExpectation.fulfill()
                    }
                }
            }else{
                pinExpectation.fulfill()
            }
        }

        // Then
        waitForExpectations(timeout: 1) { (error) in
            // Waiting for an asyncronus task to fulfill
            // to avoid the order of execution issues
            // To avoid any worst case  we re adding a timeout of 1
            XCTAssertNotNil( pinResponse, "error pin")

        }
    }
}
