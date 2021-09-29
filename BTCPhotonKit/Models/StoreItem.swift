//
//  StoreItem.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 24/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

public struct StoreItem: Codable{
    let keyId:String
    let ciphertext:Data?
    var timeValue:String
}

extension CKRecord {
    subscript(key: RecordKey) -> Any? {
        get {
            return self[key.rawValue]
        }
        set {
            self[key.rawValue] = newValue as? CKRecordValue
        }
    }
    var store:StoreItem?{
        get {
            guard let keyId = self[.keyId] as? String,
                  let timeValue = self[.timeValue] as? String else{
                return nil
            }
            return StoreItem(keyId: keyId,
                             ciphertext: self[.ciphertext] as? Data,
                             timeValue:timeValue )
        }
        set {
            self[.keyId] = newValue?.keyId
            self[.timeValue] = newValue?.timeValue
            self[.ciphertext] = newValue?.ciphertext
        }
    }
}

