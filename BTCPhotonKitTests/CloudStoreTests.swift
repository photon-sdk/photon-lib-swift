//
//  Cloudstore.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//
   
    
import XCTest
@testable import BTCPhotonKit

class CloudStoreTests: XCTestCase {
    
    private var cloudStore: CloudStore!
    private var keyId = "8abe1a93-6a9c-490c-bbd5-d7f11a4a9c8f";
    private var phone = "+4917512345678";
    private var email = "jon.smith@example.com";
    private var ciphertext = Data(base64Encoded: "encrypted stuff")

    override func setUp() {
        super.setUp()
        cloudStore = CloudStore()
    }

    override func tearDown() {
        cloudStore = nil
        super.tearDown()
    }

    
    func testPutKey() {
        XCTAssertThrowsError(try cloudStore.putKey(keyId: keyId, ciphertext: nil), "fail on invalid args") { error in
            XCTAssertEqual(error as? CloudstoreError, CloudstoreError.invalid, "fail on invalid args")
                }
        // XCTAssertEqual(mockAsyncStorage.setItem.mock.calls.length, 0, "fail on invalid args")
        XCTAssertNoThrow(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext), "Store Item")
        
        XCTAssertThrowsError(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext)) { error in
            XCTAssertEqual(error as? CloudstoreError, CloudstoreError.alreadyPresent, "should not backup twice")
                }
        
        // XCTAssertEqual(mockAsyncStorage.setItem.mock.calls.length, 2, "should not backup twice")
    }
    
    /// Check whether fetching the key works
    func testGetKey() {
        XCTAssertNil(cloudStore.getKey(), "should not find item")
        XCTAssertNoThrow(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext), "Store Item")
        let tupleStructure = (keyId:keyId, cipherText:ciphertext)
        XCTAssertTrue(cloudStore.getKey() as! (keyId: String, cipherText: Data?) == tupleStructure, "should get stored item by userId number")
    }
    
    /// Check whether removing keyid works
    func testRemoveKeyId() {
        XCTAssertThrowsError(try cloudStore.removeKeyId(keyId: "invalid")) { error in
            XCTAssertEqual(error as? CloudstoreError, CloudstoreError.notFound, "Fail on invalid ags")
                }
        
        XCTAssertNoThrow(try cloudStore.putKey(keyId: keyId, ciphertext: ciphertext))
        XCTAssertTrue(cloudStore.getKey() as! (keyId: String, cipherText: Data?) == (keyId:keyId, cipherText:ciphertext))
        XCTAssertNoThrow(try cloudStore.removeKeyId(keyId: keyId), "should remove stored item")
        XCTAssertNil(cloudStore.getKey())
    }
    
    /// Check whether saving a phone number on the cloud works as expected
    func testPutPhone() {
        XCTAssertThrowsError(try cloudStore.putPhone(userId: "")) { error in
            XCTAssertEqual(error as? CloudstoreError, CloudstoreError.invalid, "Fail on invalid ags")
                }
        XCTAssertNoThrow(try cloudStore.putPhone(userId: phone), "Store Item")
    }
    
    /// Check whether retrieving a phone number on the cloud works as expected
    func testGetPhone() {
        XCTAssertNil(cloudStore.getPhone(), "should not find item")
        XCTAssertNoThrow(try cloudStore.putPhone(userId: phone), "Store Item")
        XCTAssertEqual(cloudStore.getPhone(), phone, "Should get stored item by userId number")

    }
    
    /// Check whether removing a phone number on the cloud works as expected
    func testRemovePhone() {
        XCTAssertNoThrow(try cloudStore.putPhone(userId: phone), "Store Item")
        XCTAssertEqual(cloudStore.getPhone(), phone, "Should get stored item by userId number")
        XCTAssertNoThrow(try cloudStore.removePhone())
        XCTAssertNil(cloudStore.getPhone())
    }
    
    /// Check whether saving an email address on the cloud works as expected
    func testPutEmail() {
        XCTAssertThrowsError(try cloudStore.putEmail(userId: "")) { error in
            XCTAssertEqual(error as? CloudstoreError, CloudstoreError.invalid, "fail on invalid args")
                }
        XCTAssertNoThrow(try cloudStore.putEmail(userId: email), "Store Item")

    }
    
    /// Check whether fetching an email address from the cloud works as expected
    func testGetEmail() {
        XCTAssertNil(cloudStore.getEmail(), "should not find item")
        XCTAssertNoThrow(try cloudStore.putEmail(userId: email), "Store Item")
        XCTAssertEqual(cloudStore.getEmail(), email, "should get stored item by userId number")
    }
    
    /// Check whether removing an email address from the cloud works as expected
    func testRemoveEmail() {
        XCTAssertNoThrow(try cloudStore.putEmail(userId: email))
        XCTAssertEqual(cloudStore.getEmail(), email, "should get stored item by userId number")
        XCTAssertNoThrow(try cloudStore.removeEmail())
        XCTAssertNil(cloudStore.getEmail(), "stored item should be remove")
    }

}
