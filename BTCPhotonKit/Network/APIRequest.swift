//
//  APIRequest.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct APIRequest {
    var baseURL: URL?
    var path: String
    var method: HTTPMethod
    var parameters: [String: Any]?
    var headers: [String: Any]?
    var body: NetworkBody?
    init( url: String, path: String, method: HTTPMethod, parameters: [String: Any]? = nil, headers: [String: Any]? = nil, body: NetworkBody? = nil) {
        self.baseURL = url.toUrl()
        self.path = path
        self.method = method
        self.parameters = parameters
        self.headers = headers
        self.body = body
    }
}

extension APIRequest {

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
    func addPath(_ path: String, to request: inout URLRequest) {
        guard !path.isEmpty else {
            return
        }

        let url = request.url?.appendingPathComponent(path)
        request.url = url
    }

    func addMethod(_ method: HTTPMethod, to request: inout URLRequest) {
        request.httpMethod = method.name
    }

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

    func addHeaders(_ headers: [String: Any]?, to request: inout URLRequest) {
        guard let headers = headers else {
            return
        }

        headers.forEach { request.setValue(String(describing: $0.value), forHTTPHeaderField: $0.key) }
    }

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
