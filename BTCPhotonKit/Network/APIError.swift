//
//  APIError.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct APIError: Error, LocalizedError {
    let message: String
    var data: Data?
    var statusCode: Int?
    var errorDescription: String? {
        return message
    }
    func errorResponse<T: Decodable>(for type: T.Type? = nil) -> T? {
        guard let data = self.data else {
            return nil
        }
        do {
            let errorResponse = try JSONDecoder().decode(T.self, from: data)
            return errorResponse
        } catch {
            return nil
        }
    }
}
