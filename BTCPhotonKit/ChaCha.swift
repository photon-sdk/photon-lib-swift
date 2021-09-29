//
//  ChaCha.swift
//  chacha
//
//  Created by Leon Johnson on 27/09/2020.
//  Copyright © 2020 Leon Johnson. All rights reserved.
//

import Foundation
import CryptoKit

public class ChaCha {
    
    enum ChaChaErrors: Error {
    case keyIsWrongSize
    }
    
    public init(){}
    
    public func generateKey() -> SymmetricKey {
        /**
         Generates a random key that is 32 bytes in length
         - Returns:             A 32 byte key
        */
        let key = SymmetricKey(size: .bits256)
        return key
    }
    
    public func encrypt(secret:Data, key:Data) throws -> Data? {
        /**
         Encrypts a secret (Data) using a key (Data). It returns a data object (bytes) or nil.

         - Parameters:
            - secret:           The data being encrypted
            - key:              the key needed to decrypt the data
         - Returns:             The encrypted data
        */
        let symmetric_key = SymmetricKey(data: key)
        guard symmetric_key.bitCount == 256 else {
            print("The key is the not 32 bytes long")
            throw ChaChaErrors.keyIsWrongSize
        }
        let sealedBox = try? ChaChaPoly.seal(secret, using: symmetric_key).combined
        return sealedBox
    }
    
    public func decrypt(cipher_bytes:Data, key:Data) throws -> Data? {
        /**
         Decrypts a secret (Data) using a key (Data). It returns a data object (bytes) or nil.

         - Parameters:
            - cipher_bytes:     The data being decrypted
            - key:              the key needed to decrypt the data
         - Returns:             The decrypted data
        */
        let sealedBox = try! ChaChaPoly.SealedBox(combined: cipher_bytes) // turn bytes to a sealedbox
        let symmetric_key = SymmetricKey(data: key) // turn bytes to a SymmetricKey
        
        // check the key is 32 bytes in length
        guard symmetric_key.bitCount == 256 else {
            print("The key is the not 32 bytes long")
            throw ChaChaErrors.keyIsWrongSize
        }
        
        let openedBox = try? ChaChaPoly.open(sealedBox, using: symmetric_key) // Open the box with the key
        let original_secret = String(decoding: openedBox!, as: UTF8.self) // convert the data (bytes) to a string
        print("The decrypted data is: \(original_secret)")
        return openedBox
    }
}
