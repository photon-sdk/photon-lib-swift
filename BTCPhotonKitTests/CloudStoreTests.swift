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
    private var ciphertext = "encrypted stuff".data(using: .utf8)

    override func setUp() {
        super.setUp()
        cloudStore = CloudStore(store: MockCloudDAO())
    }

    override func tearDown() {
        cloudStore = nil
        super.tearDown()
    }


    func testPutKeyWithInvalidCiphertext() {

        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be failed with Invalid Error")
        // holds any response/error need to check on expectation
        var mError: Error?
        cloudStore.putKey(keyId: keyId, ciphertext: nil) { (result) in
            if case .failure(let error) = result {
                mError = error
            }
            mExpectation.fulfill()
        }
        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertNotNil(
                mError,"Exepecting to be failed with Invalid Error")
        }
    }

    func testPutKeySuccess() {
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Bool?
        cloudStore.putKey(keyId: keyId, ciphertext: ciphertext) { (result) in
            if case .success(let status) = result {
                mResponse = status
            }
            mExpectation.fulfill()
        }
        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertEqual(
                mResponse,
                true,
                "Exepecting to be successfully put key")
        }
    }

    func testGetKeyError() {
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Data?
        cloudStore.getKey { (result) in
            if case .success(let data) = result {
                mResponse = data.ciphertext
            }
            mExpectation.fulfill()
        }
        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertNil(
                mResponse,
                "should not find item")
        }
    }
    func testGetKey() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Data?
        cloudStore.putKey(keyId: keyId,
                          ciphertext: ciphertext) {
            (result) in
            if case .success = result {
                self.cloudStore.getKey { (result) in
                    if case .success(let data) = result {
                        mResponse = data.ciphertext
                    }
                    mExpectation.fulfill()
                }
            }else{
                mExpectation.fulfill()
            }
        }
        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should not find item")
        }
    }

    func testGetKeyData() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Data?
        cloudStore.putKey(keyId: keyId,
                          ciphertext: ciphertext) {
            (result) in
            if case .success = result {
                self.cloudStore.getKey { (result) in
                    if case .success(let status) = result {
                        mResponse = status.ciphertext
                    }
                    mExpectation.fulfill()
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should not find item")

            XCTAssertTrue( (mResponse == self.ciphertext) == true ,"should get stored item by userId number")


        }
    }

    func testRemoveInvalidKeyId() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be fail")
        // holds any response/error need to check on expectation
        var mResponse: Bool?
        cloudStore.removeKeyId {
            (result) in

                    if case .success(let status) = result {
                        mResponse = status
                    }
                    mExpectation.fulfill()

        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1) { (_) in
            XCTAssertNil(
                mResponse,
                "should not find item")
        }
    }

    func testRemoveKeyId() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Bool?
        cloudStore.putKey(keyId: keyId,
                          ciphertext: ciphertext) {
            (result) in
            if case .success = result {
                self.cloudStore.getKey { (result) in
                    if case .success = result {

                        self.cloudStore.removeKeyId{
                            result in

                            if case .success(let data) = result {
                                mResponse = data
                            }
                            mExpectation.fulfill()
                        }

                    }else{
                        mExpectation.fulfill()
                    }
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should find and removed the item")
        }
    }

    func testPutPhoneError() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be error")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putPhone(userId: ""){
            (result) in
            if case .success(let data) = result {
                mResponse = data?.recordType
            }
            mExpectation.fulfill()

        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNil(
                mResponse,
                "should fail save")
        }
    }

    func testPutPhone() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putPhone(userId: phone){
            (result) in
            if case .success(let data) = result {
                mResponse = data?.recordType
            }
            mExpectation.fulfill()
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should save item")
        }
    }

    func testGetPhoneError() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        self.cloudStore.getPhone{
            result in
            if case .success(let data) = result {
                mResponse = data
            }
            mExpectation.fulfill()
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNil(
                mResponse,
                "should get item")
        }
    }

    func testGetPhone() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putPhone(userId: phone){
            (result) in
            if case .success = result{

                self.cloudStore.getPhone{
                    result in
                    if case .success(let data) = result {
                        mResponse = data
                    }

                    mExpectation.fulfill()
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should get item")
        }
    }

    func testRemovePhone() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Bool?
        cloudStore.putPhone(userId: phone){
            (result) in
            if case .success = result{
                self.cloudStore.getPhone{
                    result in
                    if case .success = result{

                        self.cloudStore.removePhone{
                            result in
                            if case .success(let data) = result {
                                mResponse = data
                            }
                            mExpectation.fulfill()
                        }
                    }else{
                        mExpectation.fulfill()
                    }
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should get item and removed")
        }
    }



    func testPutEmailError() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be error")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putEmail(userId: ""){
            (result) in
            if case .success(let data) = result {
                mResponse = data?.recordType
            }
            mExpectation.fulfill()

        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNil(
                mResponse,
                "should fail save")
        }
    }

    func testPutEmail() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putEmail(userId: email){
            (result) in
            if case .success(let data) = result {
                mResponse = data?.recordType
            }
            mExpectation.fulfill()
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should save item")
        }
    }

    func testGetEmailError() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        self.cloudStore.getEmail{
            result in
            if case .success(let data) = result {
                mResponse = data
            }
            mExpectation.fulfill()
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNil(
                mResponse,
                "should get item")
        }
    }

    func testGetEmail() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: String?
        cloudStore.putEmail(userId: email){
            (result) in
            if case .success = result{

                self.cloudStore.getEmail{
                    result in
                    if case .success(let data) = result {
                        mResponse = data
                    }

                    mExpectation.fulfill()
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should get item")
        }
    }

    func testRemoveEmail() {
        cloudStore.store.clear()
        // expectation to handle the async task
        let mExpectation = expectation(description:
                                        "Exepecting to be success")
        // holds any response/error need to check on expectation
        var mResponse: Bool?
        cloudStore.putEmail(userId: email){
            (result) in
            if case .success = result{
                self.cloudStore.getEmail{
                    result in
                    if case .success = result{

                        self.cloudStore.removeEmail{
                            result in
                            if case .success(let data) = result {
                                mResponse = data
                            }
                            mExpectation.fulfill()
                        }
                    }else{
                        mExpectation.fulfill()
                    }
                }
            }else{
                mExpectation.fulfill()
            }
        }

        // Waiting for an asyncronus task to fulfill
        // to avoid the order of execution issues
        // To avoid any worst case of Expectation we are adding a timeout of 1
        waitForExpectations(timeout: 1000) { (_) in
            XCTAssertNotNil(
                mResponse,
                "should get item and removed")
        }
    }
}
