//
//  KeyServerResponse.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 01/03/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation

struct KeyServerResponse: Codable {
    let id:String?
    let message:String?
    let delay:String?
    let encryptionKey: Data?
}
