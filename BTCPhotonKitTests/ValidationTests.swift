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
        verify = Verify()
        mockText = MockText()
    }

    override func tearDown() {
        verify = nil
        mockText = nil
    }
    
    /// This unit test checks whether our validation of the phone number is correct
    func testPhoneNumber() throws {
        XCTAssertTrue(verify.isPhone("+4917512345678"), "returns true for a valid phone number")
        XCTAssertFalse(verify.isPhone("+04917512345678"), "returns false for a invalid phone number")
        XCTAssertFalse(verify.isPhone("+4"), "returns false for a invalid phone number")
        XCTAssertFalse(verify.isPhone("004917512345678"), "returns false for a invalid phone number")
        XCTAssertFalse(verify.isPhone(""), "returns false for empty string")
        XCTAssertFalse(verify.isPhone("null"), "returns false for null")
        XCTAssertFalse(verify.isPhone("undefined"), "returns false for undefined")
    }
    
    /// This unit test checks whether our validation of the email address is correct
    func testEmail() {
        XCTAssertTrue(verify.isEmail(email: "jon.smith@example.com"), "returns true for a valid email address")
        XCTAssertFalse(verify.isEmail(email: "@example.com"), "returns false for an invalid email address")
        XCTAssertFalse(verify.isEmail(email: "jon.smith@examplecom"), "returns false for an invalid email address")
        XCTAssertFalse(verify.isEmail(email: "jon.smithexamplecom"), "returns false for an invalid email address")
        XCTAssertFalse(verify.isEmail(email: ""), "returns false for empty string")
        XCTAssertFalse(verify.isEmail(email: "null"), "returns false for null")
        XCTAssertFalse(verify.isEmail(email: "undefined"), "returns true for a valid phone number")
    }
    
    /// This unit test checks whether our validation of the code is correct
    func testCode() throws {
        XCTAssertTrue(verify.isCode(code: "000000"), "returns true for a valid code")
        XCTAssertFalse(verify.isCode(code: "00000a"), "returns false for a non digit code")
        XCTAssertFalse(verify.isCode(code: "00000"), "returns false for a code that is too short")
        XCTAssertFalse(verify.isCode(code: "0000000"), "returns false for a code that is too long")
        XCTAssertFalse(verify.isCode(code: "null"), "returns false for null")
        XCTAssertFalse(verify.isCode(code: "undefined"), "returns false for undefined")
        XCTAssertFalse(verify.isCode(code: ""), "returns false for a empty string")
    }
    
    /// This unit test checks whether our validation of the id is correct
    func testId() throws {
        XCTAssertTrue(verify.isId(id: "8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f"), "returns true for a valid UUID")
        XCTAssertFalse(verify.isId(id: "8ABE1A93-6A9C-490C-BBD5-D7F11A4A9C8F"), "returns false for an upper case uuid")
        XCTAssertFalse(verify.isId(id: "8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8"), "returns false for invalid UUID")
        XCTAssertFalse(verify.isId(id: "0000000"), "returns false for a code that is too long")
        XCTAssertFalse(verify.isId(id: "null"), "returns false for null")
        XCTAssertFalse(verify.isId(id: "undefined"), "returns false for undefined")
        XCTAssertFalse(verify.isId(id: ""), "returns false for a empty string")
    }
    
    /// This unit test checks whether our validation of the pin is correct
    func testPin() throws {
        XCTAssertTrue(verify.isPin(pin: "1234"), "returns true for a four digit pin")
        XCTAssertTrue(verify.isPin(pin: "#!Pa$$wörD"), "returns true for a password")
        XCTAssertTrue(verify.isPin(pin: "this is a passphrase"), "returns true for a passphrase")
        XCTAssertFalse(verify.isPin(pin: "123"), "returns false for only three digits")
        XCTAssertFalse(verify.isPin(pin: "1234\n"), "returns false for a new line")
        XCTAssertFalse(verify.isPin(pin: mockText.randomString(length: 257)), "returns false if pin is too long")
        XCTAssertFalse(verify.isPin(pin: ""), "returns false for a empty string")
    }
    
}
