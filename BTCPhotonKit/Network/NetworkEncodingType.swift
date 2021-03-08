//
//  NetworkSession.swift
//  photon-swift
//
//  Created by Leon Johnson on 09/01/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

enum NetworkEncodingType {
    case json
}

extension NetworkEncodingType {
    var contentTypeValue: String {
        switch self {
            case .json:
                return "application/json"
        }
    }
}
