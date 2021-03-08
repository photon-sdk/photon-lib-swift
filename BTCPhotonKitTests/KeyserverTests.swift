//
//  Keyserver.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import XCTest
@testable import BTCPhotonKit
class KeyserverTests: XCTestCase {

    var keyServer: Keyserver!
    let keyId = "some-id"
    let userId = "+4917512345678"
    let code = "000000"
    let pin = "1234"
    let newPin = "5678"

    override func setUp() {
        keyServer = Keyserver("http://localhost:8000")
    }

    override func tearDown() {
        keyServer = nil
    }


    func testCreateKeyAPiError(){
        // Given
        let session  = MockURLSession(error: GenericError(message: "Error"))
        keyServer.client = NetworkingLayer(session: session)
        let pinExpectation = expectation(description: "KeyserverTests")
        var pinResponse: String?
        let mError:Error?
        
        // When
        _ = keyServer.createKey(pin: pin)
        pinExpectation.fulfill()
        
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertNil(pinResponse,"should fail on api error")
        }
    }
    
    /// Key creation
    func testCreateKey(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" }".data(using: .ascii), urlResponse: nil, error: nil)
        keyServer.client = NetworkingLayer(session: session)
        let pinExpectation = expectation(description: "should fail on api error")
        var pinResponse: String?
        let mError:Error?
        
        // When
        _ = keyServer.createKey(pin: pin)
        pinExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(pinResponse,"some-id","should return key id on success")
        }
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key","should return key id on success")
    }
    
    ///
    func testFetchKeyAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        _ = keyServer.fetchKey(keyId: keyId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    ///
    func testFetchKeyRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 429)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        _ = keyServer.fetchKey(keyId: keyId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
        }
    }
    
    ///
    func testFetchKey(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"encryptionKey\" : \"some-key\"}".data(using: .ascii))
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Data?
        
        // When
        _ = keyServer.fetchKey(keyId: keyId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(String(decoding: mResponse!, as: UTF8.self),"some-key","should return encryption key on success")
        }
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id","should return encryption key on success")
    }
    
    /// This unit test checks whether our validation of the phone number is correct
    func testChangePinAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        _ = keyServer.fetchKey(keyId: keyId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    
    func testChangePinRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 429)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.changePin(keyId:keyId , newPin: newPin)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
        }
    }
    
    
    func testChangePin(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"message\" : \"Success\"}".data(using: .ascii))
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        // When
        keyServer.changePin(keyId:keyId , newPin: newPin)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should set new pin on successs")
        }
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id","should set new pin on success")
    }


    func testCreateUserAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.createUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    
    func testCreateUserRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 429) //429 ==  Too Many Requests
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.createUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
        }
    }
    
    
    func testCreateUser(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"message\" : \"Success\"}".data(using: .ascii),statusCode: 201)
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        // When
        keyServer.createUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()

        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should return 201 on success")
        }
        
        // Then
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id/user","should return 201 on success")
    }

    
    func testVerifyUserAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.verifyUser(keyId: keyId, userId: userId, code: code)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    
    func testVerifyUserRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 429)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.verifyUser(keyId: keyId, userId: userId, code: code)
        mExpectation.fulfill()

        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
        }
    }
    
    
    func testVerifyUser(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"message\" : \"Success\"}".data(using: .ascii),statusCode: 200)
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        // When
        keyServer.verifyUser(keyId: keyId, userId: userId, code: code)
        mExpectation.fulfill()
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should return 200 on success")
        }
        
        // Then
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id/user/\("+4917512345678".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")","should return 200 on success")
    }
    
    
    func testInitPinResetAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.initPinReset(keyId: keyId, userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    func testInitPinReset(){
        // Given
        let session = MockURLSession(data: "{ \"message\" : \"Success\"}".data(using: .ascii),statusCode: 200)
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        // When
        keyServer.initPinReset(keyId: keyId, userId: userId)
        mExpectation.fulfill()
        
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should return 200 on success")
        }
        
        // Then
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id/user/\("+4917512345678".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")/reset","should return 200 on success")
    }
    
    
    func testVerifyPinResetAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        _ = keyServer.verifyPinReset(keyId: keyId, userId: userId, code: code, newPin: newPin)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    
    func testVerifyPinResetRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 423)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        _ = keyServer.verifyPinReset(keyId: keyId, userId: userId, code: code, newPin: newPin)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
            if let nError = mError as? RateLimitError{
                XCTAssertEqual(nError.delay ,"2020-06-01T03:33:47.980Z","should throw delay error on rate limit")
            }else{
                XCTFail("should throw delay error on rate limit")
            }
        }
    }
    
    
    func testVerifyPinReset(){
        // Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"message\" : \"Success\"}".data(using: .ascii),statusCode: 200)
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        // When
        _ = keyServer.verifyPinReset(keyId: keyId, userId: userId, code: code, newPin: newPin)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should return 200 on success")
        }
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id/user/\("+4917512345678".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")","should return 200 on success")
    }
    
    
    func testDeleteUserAPiError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"boom\"}".data(using: .ascii), statusCode: 500)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.removeUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"boom","should fail on api error")
        }
    }
    
    
    func testDeleteUserRateLimitError(){
        // Given
        let mockURLSession  = MockURLSession(data: "{ \"message\": \"Time locked until\", \"delay\": \"2020-06-01T03:33:47.980Z\" }".data(using: .ascii), statusCode: 429)
        keyServer.client = NetworkingLayer(session: mockURLSession)
        let mExpectation = expectation(description: "KeyserverTests")
        var mError:Error?
        
        // When
        keyServer.removeUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertEqual(mError?.localizedDescription,"RateLimitError","should throw delay error on rate limit")
        }
    }
    
    
    func testDeleteUser(){
        //Given
        let session = MockURLSession(data: "{ \"id\": \"some-id\" ,\"message\" : \"Success\"}".data(using: .ascii),statusCode: 201)
        keyServer.client = NetworkingLayer(session: session)
        let mExpectation = expectation(description: "KeyserverTests")
        var mResponse: Bool = false
        
        //When
        keyServer.removeUser(keyId:keyId , userId: userId)
        mExpectation.fulfill()
        
        // Then
        waitForExpectations(timeout: 1) { (error) in
            XCTAssertTrue(mResponse,"should return 200 on success")
        }
        XCTAssertEqual(session.cachedUrl?.path,"/v2/key/some-id/user/\("+4917512345678".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? "")","should return 200 on success")
    }

}
