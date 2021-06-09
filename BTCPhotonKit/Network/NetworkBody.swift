//
//  NetworkBody.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

/// This Netywork Body class help the user to handle the APi in a dictionary  or Encodable
struct NetworkBody {

    let data: Data // the data to be send on API Request
    let encoding: NetworkEncodingType // type of encoding

    // Initialise with data itself
    init(data: Data, encoding: NetworkEncodingType = .json) {
        self.data = data
        self.encoding = encoding
    }

    // if we have a dictionary data it will convert to the Data and initialise
    init(dictionary: [String: Any], encoding: NetworkEncodingType = .json) throws {

        var data: Data
        switch encoding {
        case .json:
            data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
        }
        self.init(data: data, encoding: encoding)
    }

    // if we have a Encodable it will convert to the Data and initialise
    init<E: Encodable>(object: E, encoding: NetworkEncodingType = .json) throws {
        let data = try JSONEncoder().encode(object)
        self.init(data: data, encoding: encoding)
    }
}
