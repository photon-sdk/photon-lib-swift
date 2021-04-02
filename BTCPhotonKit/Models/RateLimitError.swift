//
//  RateLimitError.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct RateLimitError: Error, LocalizedError {
    let message: String
    let delay: String?
    let statusCode: Int?
    var errorDescription: String? {
        return message
    }
}
