//
//  APIRequest.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation


// APIRequest is a Support Class for NetworkLayer
// We need to create an APIrequest to call an API in the netwokringlayer 
struct APIRequest {

    var baseURL: URL? // base url for call
    var path: String  // path after url
    var method: HTTPMethod // normal http methos
    var parameters: [String: Any]? // query parameters
    var headers: [String: Any]? // headers if needed
    var body: NetworkBody? // Body of the request

    init( url: String, path: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil, headers: [String: Any]? = nil, body: NetworkBody? = nil) {
        self.baseURL = url.toUrl()
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
}
// MARK: Helpers
extension APIRequest {
    // this is to create a URLRequest and it's used in networkLayer
    func buildURLRequest() -> URLRequest? {
        guard let baseURL = baseURL else {
            return nil
        }
        var urlRequest = URLRequest(url: baseURL)
        addPath(path, to: &urlRequest)
        addMethod(method, to: &urlRequest)
        addQueryParameters(parameters, to: &urlRequest)
        addHeaders(headers, to: &urlRequest)
        addRequestBody(body, to: &urlRequest)

        return urlRequest
    }
    // Add the necesary components to form a complete URL
    var url: URL? {
        guard let baseURL = baseURL else {
            return nil
        }
        guard !path.isEmpty else {
            return baseURL
        }
        return baseURL.appendingPathComponent(path)
    }

}

// MARK: - Private Helpers
private extension APIRequest {

    // updating URLRequest with path
    func addPath(_ path: String, to request: inout URLRequest) {
        guard !path.isEmpty else {
            return
        }

        let url = request.url?.appendingPathComponent(path)
        request.url = url
    }

    // updating URLRequest with method
    func addMethod(_ method: HTTPMethod, to request: inout URLRequest) {
        request.httpMethod = method.name
    }

    // updating URLRequest with parameters
    func addQueryParameters(_ parameters: [String: Any]?, to request: inout URLRequest) {
        guard let parameters = parameters,
              let url = request.url else {
            return
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        let queryItems = parameters.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
        components?.queryItems = queryItems

        request.url = components?.url
    }

    // updating URLRequest with headers
    func addHeaders(_ headers: [String: Any]?, to request: inout URLRequest) {
        guard let headers = headers else {
            return
        }

        headers.forEach { request.setValue(String(describing: $0.value), forHTTPHeaderField: $0.key) }
    }

    // updating URLRequest with the body
    func addRequestBody(_ body: NetworkBody?, to request: inout URLRequest) {
        guard let body = body else {
            return
        }
        switch body.encoding {
        case .json:
            request.setValue(body.encoding.contentTypeValue, forHTTPHeaderField: "Content-Type")
            request.httpBody = body.data
        }
    }
}
