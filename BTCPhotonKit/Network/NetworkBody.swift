//
//  NetworkBody.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct NetworkBody {

    let data: Data
    let encoding: NetworkEncodingType

    init(data: Data, encoding: NetworkEncodingType) {
        self.data = data
        self.encoding = encoding
    }
    init(dictionary: [String: Any], encoding: NetworkEncodingType) throws {

        var data: Data
        switch encoding {
            case .json:
                data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        }
        self.init(data: data, encoding: encoding)
    }
    init<E: Encodable>(object: E, encoding: NetworkEncodingType) throws {
        let data = try JSONEncoder().encode(object)
        self.init(data: data, encoding: encoding)
    }
}
