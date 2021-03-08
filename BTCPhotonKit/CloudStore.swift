//
//  Cloudstore.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

/// Enum to maintain error conditions in the app.
enum CloudstoreError: Error {
    case tooShort
    case alreadyPresent
    case invalid
    case notFound
    case customMessage(message: String)
}

 ///  Manages getting, setting, and removing encrypted keys, phone number and email from iCloud using native API's.
public class CloudStore {

    //let verify = Verify()

    let VERSION = "1"
    let KEY_ID = "1_photon_key_id"
    let PHONE = "1_photon_phone"
    let EMAIL = "1_photon_email"

    let store = CKContainer.default().privateCloudDatabase

    func putKey(keyId: String, ciphertext: Data?) throws {
        /// Encrypted key storage
        /// - Parameters:
        ///   - keyId: keyId description
        ///   - ciphertext: ciphertext description
        /// - Throws: description
        if !Verify.isId(keyId) || ciphertext != nil {
            throw CloudstoreError.invalid
        }

        if getItem(keyId: KEY_ID) != ""{
            throw CloudstoreError.alreadyPresent
        }
        setItem(keyId: KEY_ID, value: keyId)
        setItem(keyId: shortKeyId(keyId: keyId), value: stringifyKey(keyId: keyId, ciphertext: ciphertext))

    }
    
    func getKey() -> Any? {
        /// Get Encrypted key storage
        /// - Returns: return key
        let keyId = getItem(keyId: KEY_ID)

        if keyId == "" {
            return nil
        }
        var key = getItem(keyId: shortKeyId(keyId: keyId))

        if key != ""{
            key = parseKey(item: key) as! String
        } else {
            return nil
        }
        return key
    }

    func removeKeyId(keyId: Any) throws {
        /// Remove KeyId
        /// - Parameter keyId: keyId
        removeItem(keyId: KEY_ID)
    }

    func putPhone(userId: String)throws {
        /// Save userPhone in local storate /iCloud Storage
        /// - Parameter userId: userId
        /// - Throws: description
        if !Verify.isPhone(userId) {
            throw  CloudstoreError.invalid
        }
        setItem(keyId: PHONE, value: userId)
    }

    func getPhone() -> String {
        /// Get Phone
        /// - Returns: phone
        return getItem(keyId: PHONE)
    }

    func removePhone() {
        /// Remove Phone
        /// - Parameter phone: phone
        removeItem(keyId: PHONE)
    }

    func putEmail(userId: String) throws {
        // Save Email address in local storate /iCloud Storage
        // - Parameter userId: userId
        // - Throws: description
        if !Verify.isEmail(userId) {
            throw  CloudstoreError.invalid
        }
        setItem(keyId: EMAIL, value: userId)
    }

    func getEmail() -> String {
        // Get Email address from local storate /iCloud Storage
        // - Returns: email address
        return getItem(keyId: EMAIL)
    }

    func removeEmail() {
        // Remove Email address from local storate /iCloud Storage
        // - Parameter email:email address
        removeItem(keyId: EMAIL)
    }
    
    
    // Helper functions
    
    func shortKeyId(keyId: String) -> String {
        let shortId = keyId.replacingOccurrences(of: "/-/g", with: "").prefix(8)
        return "\(VERSION)_\(shortId)"
    }

    func stringifyKey(keyId: String, ciphertext: Data?) -> Any {
        let timeValue = StringHelpers.time_toISOString()
        return StringHelpers.stringify(json: [keyId: keyId, ciphertext: ciphertext?.base64EncodedString(), timeValue: timeValue])
    }

    func parseKey(item: Any) -> Any {
        let key: [ItemData] = try! JSONDecoder().decode([ItemData].self, from: item as! Data)
        return key
    }

    struct ItemData: Decodable {
        let keyId: String
        let ciphertext: Data?
        let time: Date?
    }

    func setItem(keyId: Any, value: Any) {
        let record = CKRecord(recordType: value as! CKRecord.RecordType)
        record.setValue(keyId, forKey: "keyId")
        store.save(record) { (_, error) in
            if error == nil {
                print("Record Saved")
            } else {
                print("Record Not Saved")
            }
        }
    }

    func getItem(keyId: Any) -> String {
        var key = String()
        let query = CKQuery.init(recordType: keyId as! CKRecord.RecordType, predicate: NSPredicate(value: true))
        store.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                return
            }
            key = records.first?.value(forKey: "keyId") as? String ?? ""
        }
        return key
    }

    static func delete(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        CKContainer.default().publicCloudDatabase.delete(withRecordID: recordID) { (recordID, err) in
            DispatchQueue.main.async {
                if let err = err {
                    completion(.failure(err))
                    return
                }
                guard let recordID = recordID else {
                    completion(.failure(CloudstoreError.invalid))
                    return
                }
                completion(.success(recordID))
            }
        }
    }

    func removeItem(keyId: Any) {
        // MARK: - delete from CloudKit
        CloudStore.delete(recordID: keyId as! CKRecord.ID) { (result) in
            switch result {
            case .success:
                print("Successfully deleted item")
            case .failure(let err):
                print(err.localizedDescription)
            }
        }
    }
}

extension CloudstoreError: Equatable {
    public static func ==(lhs: CloudstoreError, rhs: CloudstoreError) -> Bool {
        switch (lhs, rhs) {
        case (.tooShort, .tooShort):
            return true
        case (.invalid, .invalid):
            return true
        case (.alreadyPresent, .alreadyPresent):
            return true
        case (.customMessage, .customMessage):
            return true
        default:
            return false
        }
    }
}
