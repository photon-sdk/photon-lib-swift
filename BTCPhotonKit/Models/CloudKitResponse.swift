//
//  CloudKitResponse.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 15/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct CloudData: Decodable {
    let keyId: String
    let ciphertext: Data?// the encrypted seed
    let time: Date?
}
