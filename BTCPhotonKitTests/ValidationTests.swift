//
//  Validation.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import XCTest
@testable import BTCPhotonKit

class MockText {
    func randomString(length: Int) -> String {
      let letters = "0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }
}


class ValidationTests: XCTestCase {
    
    private var verify: Verify!
    private var mockText: MockText!
    
    override func setUp() {
        mockText = MockText()
    }

    override func tearDown() {
        verify = nil
        mockText = nil
    }
    
    /// This unit test checks whether our validation of the phone number is correct
    func testPhoneNumber() throws {
        XCTAssertTrue(Verify.isPhone("+4917512345678"), "returns true for a valid phone number")
        XCTAssertFalse(Verify.isPhone("+04917512345678"), "returns false for a invalid phone number")
        XCTAssertFalse(Verify.isPhone("+4"), "returns false for a invalid phone number")
        XCTAssertFalse(Verify.isPhone("004917512345678"), "returns false for a invalid phone number")
        XCTAssertFalse(Verify.isPhone(""), "returns false for empty string")
        XCTAssertFalse(Verify.isPhone("null"), "returns false for null")
        XCTAssertFalse(Verify.isPhone("undefined"), "returns false for undefined")
    }
    
    /// This unit test checks whether our validation of the email address is correct
    func testEmail() {
        XCTAssertTrue(Verify.isEmail("jon.smith@example.com"), "returns true for a valid email address")
        XCTAssertFalse(Verify.isEmail("@example.com"), "returns false for an invalid email address")
        XCTAssertFalse(Verify.isEmail("jon.smith@examplecom"), "returns false for an invalid email address")
        XCTAssertFalse(Verify.isEmail("jon.smithexamplecom"), "returns false for an invalid email address")
        XCTAssertFalse(Verify.isEmail(""), "returns false for empty string")
        XCTAssertFalse(Verify.isEmail("null"), "returns false for null")
        XCTAssertFalse(Verify.isEmail("undefined"), "returns true for a valid phone number")
    }
    
    /// This unit test checks whether our validation of the code is correct
    func testCode() throws {
        XCTAssertTrue(Verify.isCode("000000"), "returns true for a valid code")
        XCTAssertFalse(Verify.isCode("00000a"), "returns false for a non digit code")
        XCTAssertFalse(Verify.isCode("00000"), "returns false for a code that is too short")
        XCTAssertFalse(Verify.isCode("0000000"), "returns false for a code that is too long")
        XCTAssertFalse(Verify.isCode("null"), "returns false for null")
        XCTAssertFalse(Verify.isCode("undefined"), "returns false for undefined")
        XCTAssertFalse(Verify.isCode(""), "returns false for a empty string")
    }
    
    /// This unit test checks whether our validation of the id is correct
    func testId() throws {
        XCTAssertTrue(Verify.isId("8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f"), "returns true for a valid UUID")
        XCTAssertFalse(Verify.isId("8ABE1A93-6A9C-490C-BBD5-D7F11A4A9C8F"), "returns false for an upper case uuid")
        XCTAssertFalse(Verify.isId("8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8"), "returns false for invalid UUID")
        XCTAssertFalse(Verify.isId("0000000"), "returns false for a code that is too long")
        XCTAssertFalse(Verify.isId("null"), "returns false for null")
        XCTAssertFalse(Verify.isId("undefined"), "returns false for undefined")
        XCTAssertFalse(Verify.isId(""), "returns false for a empty string")
    }
    
    /// This unit test checks whether our validation of the pin is correct
    func testPin() throws {
        XCTAssertTrue(Verify.isPin("1234"), "returns true for a four digit pin")
        XCTAssertTrue(Verify.isPin("#!Pa$$wörD"), "returns true for a password")
        XCTAssertTrue(Verify.isPin("this is a passphrase"), "returns true for a passphrase")
        XCTAssertFalse(Verify.isPin("123"), "returns false for only three digits")
        XCTAssertFalse(Verify.isPin("1234\n"), "returns false for a new line")
        XCTAssertFalse(Verify.isPin(mockText.randomString(length: 257)), "returns false if pin is too long")
        XCTAssertFalse(Verify.isPin(""), "returns false for a empty string")
    }
    
}
