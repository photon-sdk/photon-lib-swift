//
//  NetworkingLayer.swift
//  photon-swift
//
//  Created by Leon Johnson on 09/01/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct NetworkingLayer {
    var session: URLSession = URLSession.shared
    func sendRequest<C: Decodable>(request: APIRequest, responseType: C.Type, completion: @escaping (Result<C, APIError>) -> Void) {
        if let urlRequest = request.buildURLRequest() {
            let task =  session.dataTask(with: urlRequest) { (data, response, error) in

                if let error  = error {
                    completion(.failure(APIError(message: error.localizedDescription)))
                    return
                }
                if let apiResponse =  response as? HTTPURLResponse, (apiResponse.statusCode < 200 || apiResponse.statusCode > 300) {
                    completion(.failure(APIError(message: apiResponse.description, data: data, statusCode: apiResponse.statusCode)))
                    return
                }
                guard let data = data else {
                    completion(.failure(APIError(message: "No data")))
                    return
                }
                do {
                    let value = try JSONDecoder().decode(C.self, from: data)
                    completion(.success(value))
                } catch {
                    completion(.failure(APIError(message: "Parsing Error", data: data)))
                }
            }
            task.resume()
        }
    }
}
