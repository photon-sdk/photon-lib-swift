//
//  MockAPI.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 09/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

class MockURLSession: URLSession {
    var cachedUrl: URL?
    var statusCode:Int = 200
    private let mockTask: MockTask
    init(data: Data? = nil, urlResponse: URLResponse? = nil, error: Error? = nil,statusCode:Int = 200) {
        mockTask = MockTask(data: data, urlResponse: urlResponse, error:
                                error)
        self.statusCode = statusCode
    }

    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.cachedUrl = url
        mockTask.setResponse(completionHandler:completionHandler , statusCode: statusCode, url: url)
        return mockTask
    }
    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        self.cachedUrl = request.url
        mockTask.setResponse(completionHandler:completionHandler , statusCode: statusCode, url: request.url)
        return mockTask
    }
    
}


class MockTask: URLSessionDataTask {
    private let data: Data?
    private var urlResponse: URLResponse?
    private let userError:Error?
    private var completionHandler: ((Data?, URLResponse?, Error?) -> Void)?
    init(data: Data?, urlResponse: URLResponse?, error: Error?) {
        self.data = data
        self.urlResponse = urlResponse
        self.userError = error
    }
    func setResponse(completionHandler:((Data?, URLResponse?, Error?) -> Void)?,statusCode:Int,url:URL?){
        self.completionHandler = completionHandler
        if let url = url,urlResponse == nil{
            urlResponse = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        }
    }
    override func resume() {
        DispatchQueue.main.async {
            self.completionHandler?(self.data, self.urlResponse, self.userError)
        }
    }
}
