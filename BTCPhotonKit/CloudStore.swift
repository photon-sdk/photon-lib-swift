//
//  Cloudstore.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 04/01/2021.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

public enum CloudstoreError: Error {
    case tooShort
    case alreadyPresent
    case invalid
    case notFound
    case customMessage(message: String)
}

public enum RecordKey: String {
    case phone = "photon_phone_1"
    case email = "photon_email_1"
    case keyId = "photon_key_id_1"
    case shortKeyID
    case ciphertext
    case timeValue
}

 ///  Manages getting, setting, and removing encrypted keys, phone number and email from iCloud using native API's.
public class CloudStore {
    /*
     CloudKit Model:
     Phone
     Email
     key_id
     shortKeyID
     
     */
    
    let VERSION = "1"
    let store:CloudDAO
    
    public init(store:CloudDAO = CloudKitDAO() ) {
        self.store = store
    }
    
    /// Encrypted key storage
    /// - Parameters:
    ///   - keyId: keyId description
    ///   - ciphertext: ciphertext description
    public func putKey(keyId: String, ciphertext: Data?, completion: @escaping(Result<Bool, Error>) -> Void) {
        
        if !Verify.isId(keyId) || !Verify.isBuffer(ciphertext) {
            completion(.failure(CloudstoreError.invalid))
            return
        }
        getItem(keyId: .keyId) { (result) in

            if case .success(let data) = result,
               let key:String? = self.getFirstValue(records:data, key: .keyId),
               key != nil {
                completion(.failure(CloudstoreError.alreadyPresent))
                return
            }

            self.setItem(keyId: .keyId, value: keyId){
                (result) in
                if case .success(_) = result {

                    self.setItem(keyId: .shortKeyID,
                                 value: StoreItem(keyId: keyId,
                                                  ciphertext: ciphertext,
                                                  timeValue: CloudStore.timeToISOString())){
                        (result) in
                        if case .failure(let error) = result {
                            completion(.failure(error))
                        }else{
                            completion(.success(true))
                        }

                    }
                    return
                }
                if case .failure(let error) = result {
                    completion(.failure(error))
                }

            }

        }
    }
    
    /// Get Encrypted key storage
    /// - Returns: return key
    public func getKey(completion: @escaping(Result<StoreItem, CloudstoreError>) -> Void){
        getItem(keyId: .keyId) { (result) in

            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }

            if case .success(let data) = result,
               let key:String? = self.getFirstValue(records:data, key: .keyId){

                guard key != nil else {
                    completion(.failure(.customMessage(message: "invalid value")))
                    return
                }

                self.getItem(keyId: .shortKeyID){
                    (result) in

                    if case .failure(let error) = result {
                        completion(.failure(error))
                        return
                    }
                    if case .success(let data) = result{
                        if let keyData = data?.first?.store{
                            return // review
                                completion(.success(keyData))
                        }else{
                            completion(.failure(.customMessage(message: "invalid value")))
                        }

                    }
                }
            }
        }
    }
    
    
    /// Remove KeyId
    /// - Parameter keyId: keyId
    public func removeKeyId(completion: @escaping(Result<Bool, Error>) -> Void) {
        removeItem(keyId: .keyId,completion: completion)
    }


    /// Save userPhone in local storage /iCloud Storage
    /// - Parameter userId: userId
    public func putPhone(userId:String, completion: @escaping(Result<CKRecord?, CloudstoreError>) -> Void){
        if (!Verify.isPhone(userId)) {
            completion(.failure(.invalid))
            return
        }
        setItem(keyId: .phone, value: userId){
            (result) in
            completion(result)
        }
    }

    /// Get Phone
    /// - Returns: phone
    public func getPhone(completion: @escaping(Result<String?, CloudstoreError>) -> Void) {
        return getItem(keyId: .phone){
            result in

            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }

            if case .success(let data) = result,
               let phone:String? = self.getFirstValue(records:data, key: .phone){

                guard let phone = phone else {
                    completion(.failure(.customMessage(message: "invalid value")))
                    return
                }
                completion(.success(phone))
            }
        }
    }

    /// Remove Phone
    /// - Parameter phone: phone
    public func removePhone(completion: @escaping(Result<Bool, Error>) -> Void) {
        removeItem(keyId: .phone ,completion: completion)
    }


    /**Save Email address in local storage /iCloud Storage
     - Parameter userId: userId
     */
    public func putEmail(userId: String, completion: @escaping(Result<CKRecord?, CloudstoreError>) -> Void){
        if (!Verify.isEmail(userId)) {
            completion(.failure(.invalid))
            return
        }
        setItem(keyId: .email, value: userId){
            result in
            completion(result)
        }
    }

    /**Get Email address from local storage /iCloud Storage
     - Returns: email address
     */
    public func getEmail(completion: @escaping(Result<String, CloudstoreError>) -> Void) {

        return getItem(keyId: .email){
            result in

            if case .failure(let error) = result {
                completion(.failure(error))
                return
            }

            if case .success(let data) = result,
               let email:String? = self.getFirstValue(records:data, key: .email){

                guard let email = email else {
                    completion(.failure(.customMessage(message: "invalid value")))
                    return
                }
                completion(.success(email))
            }
        }
    }

    public func removeEmail(completion: @escaping(Result<Bool, Error>) -> Void) {
        /**Remove Email address from local storage /iCloud Storage
         - Parameter email:email address
         */
        removeItem(keyId: .email, completion: completion)
    }
    
    static func timeToISOString()->String{
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        return formatter.string(from: date)

    }

    public func setItem(keyId: RecordKey,value: StoreItem, completion: @escaping(Result<CKRecord?, CloudstoreError>) -> Void){
        let record = CKRecord(recordType: keyId.rawValue)
        record.store = value
        setItem(record:record, completion: completion)
    }

    public func setItem(keyId: RecordKey,value:String, completion: @escaping(Result<CKRecord?, CloudstoreError>) -> Void){
        let record = CKRecord(recordType: keyId.rawValue)
        record[keyId] = value
        setItem(record:record, completion: completion)
    }

    public func setItem(record:CKRecord, completion: @escaping(Result<CKRecord?, CloudstoreError>) -> Void){
        store.save(record) { (savedRecord, error) in
            if let error = error {
                completion(.failure(.customMessage(message:
                                                    error.localizedDescription )))
            } else {
                completion(.success(savedRecord))
            }
        }

    }

    public func getItem(keyId: RecordKey, completion: @escaping(Result<[CKRecord]?, CloudstoreError>) -> Void){
        let query = CKQuery.init(recordType: keyId.rawValue, predicate: NSPredicate(value: true))
        store.perform(query, inZoneWith: nil) { records, error in
            if let err = error{
                completion(.failure(.customMessage(message:err.localizedDescription)))
                return
            }
            completion(.success(records))
        }
    }

    public func getFirstValue<T: Any>( records: [CKRecord]?, key: RecordKey, type: T.Type? = nil) -> T? {
        return (records?.first?[key] as? T) ?? nil
    }

    public func delete(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> ()) {
        store.delete(withRecordID: recordID) { (recordID, err) in

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

    public func removeItem(keyId: RecordKey, completion: @escaping (Result<Bool, Error>) -> ()) {
        // MARK: - delete from CloudKit
        getItem(keyId: keyId) {
            (result) in
            if case .success(let data) = result {
                if let item = data?.first{
                    self.delete(recordID: item.recordID){
                        result in
                        if case .success = result {
                            completion(.success(true))
                        }
                        if case .failure(let error) = result {
                            completion(.failure(error))
                        }
                    }
                }else{
                    completion(.failure(CloudstoreError.invalid))
                }
            }
            if case .failure(let error) = result {
                completion(.failure(error))
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
        case (.customMessage(_), .customMessage(_)):
            return true
        default:
            return false
        }
    }
}
