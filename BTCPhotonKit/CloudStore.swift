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
    /*
     
     Model:
     Phone
     Email
     key_id
     shortKeyID
     
     */
    
    let VERSION = "1"
    let KEY_ID: String
    let PHONE: String
    let EMAIL: String

    let store = CKContainer.default().privateCloudDatabase
    
    init() {
        KEY_ID = "\(VERSION)_photon_key_id"
        PHONE = "\(VERSION)_photon_phone"
        EMAIL = "\(VERSION)_photon_email"
    }
    
    func putKey(keyId: String, ciphertext: Data?) throws {
        /// Encrypted key storage
        /// - Parameters:
        ///   - keyId: keyId description
        ///   - ciphertext: ciphertext description
        /// - Throws: description
        if !Verify.isId(keyId) || ciphertext != nil {
            throw CloudstoreError.invalid
        }
        if getItem(keyId: KEY_ID) as! String != ""{
            throw CloudstoreError.alreadyPresent
        }
        setItem(keyId: KEY_ID, value: keyId)
        setItem(keyId: shortKeyId(keyId), value: stringifyKey(keyId: keyId, ciphertext: ciphertext))
    }
    
    func removeKeyId(keyId: Any) throws {
        /// - Parameter keyId: keyId
        removeItem(keyId: KEY_ID)
    }

    func putPhone(userId: String) throws {
        /// Save userPhone in local storate /iCloud Storage
        /// - Parameter userId: userId
        /// - Throws: description
        if !Verify.isPhone(userId) {
            throw  CloudstoreError.invalid
        }
        // Cloudstore has a seperate Phone record
        setItem(keyId: PHONE, value: userId)
    }

    func getPhone() -> String? {
        /// - Returns: phone
        // Cloudstore has a seperate Phone record
        return getItem(keyId: PHONE) as? String
    }

    func removePhone() {
        /// - Parameter phone: phone
        // Cloudstore has a seperate Phone record
        removeItem(keyId: PHONE)
    }

    func putEmail(userId: String) throws {
        // Consider replacing Throws with Results
        
        // Save Email address in iCloud
        // - Parameter userId: userId
        // - Throws: description
        if !Verify.isEmail(userId) {
            throw  CloudstoreError.invalid
        }
        // Cloudstore has a seperate Email record
        setItem(keyId: EMAIL, value: userId)
    }

    func getEmail() -> String {
        // Get Email address from iCloud
        // - Returns: email address
        
        // Cloudstore has a seperate Email record
        return getItem(keyId: EMAIL) as! String
    }

    func removeEmail() {
        // Remove Email address from local storate /iCloud Storage
        // - Parameter email:email address
        
        // Cloudstore has a seperate Email record
        removeItem(keyId: EMAIL)
    }
    
    // Helper functions
    
    func shortKeyId(_ keyId: String) -> String {
        let shortId = keyId.replacingOccurrences(of: "/-/g", with: "").prefix(8)
        return "\(VERSION)_\(shortId)"
    }

    func stringifyKey(keyId: String, ciphertext: Data?) -> Any {
        let timeValue = StringHelpers.time_toISOString()
        return StringHelpers.stringify(json: [keyId: keyId, ciphertext: ciphertext?.base64EncodedString(), timeValue: timeValue])
    }

    func parseKey(item: Data) -> CloudData {
        // receives JSON, and maps it using the CloudData struct, and returns it
        let key: CloudData = try! JSONDecoder().decode(CloudData.self, from: item)
        return key
    }

    func setItem(keyId: String, value: Any) {
        let record = CKRecord(recordType: value as! CKRecord.RecordType)
        // DETERMINE THE KEY BEING SET (PHONE, EMAIL, KEYID, AND THEN USE IT IN 'forKey')
        /*
         
         KEY_ID = "\(VERSION)_photon_key_id"
         PHONE = "\(VERSION)_photon_phone"
         EMAIL = "\(VERSION)_photon_email"
         */
        guard let range = keyId.range(of: "_") else {
            // need to throw
            return
        }
        let key_type = keyId[range.upperBound...].uppercased()
        record.setValue(keyId, forKey: key_type)
        store.save(record) { (_, error) in
            if error == nil {
                print("Record Saved")
            } else {
                print("Record Not Saved")
            }
        }
    }
    
    func getKey() -> CloudData? {
        let keyId = getItem(keyId: KEY_ID)
        guard keyId != nil else {
            print("Handle error")
            return nil
        }
        let key = getItem(keyId: shortKeyId(keyId as! String))
        return parseKey(item: key as! Data)
    }

    func getItem(keyId: String) -> Any {
        // A recordType is a class, a record is an instance
        var key = CKRecord(recordType: "")
        let query = CKQuery(recordType: keyId, predicate: NSPredicate(value: true))
        //let query = CKQuery.init(recordType: keyId as! CKRecord.RecordType, predicate: NSPredicate(value: true))
        store.perform(query, inZoneWith: nil) { records, error in
            guard let records = records, error == nil else {
                // Handle the error
                return
            }
            // key = (records.first!.value(forKey: "keyId") as! String?)! //This is a bit messy. Revist.
            key = records.first!
        }
        return key // This isn't correct but walk through this with Tankred
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
