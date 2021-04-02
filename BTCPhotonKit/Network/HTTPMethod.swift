//
//  HTTPMethod.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
}
extension HTTPMethod {
    var name: String {
        return rawValue.uppercased()
    }
}
