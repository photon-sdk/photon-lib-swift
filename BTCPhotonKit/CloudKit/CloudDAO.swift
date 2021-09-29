//
//  CloudDAO.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 18/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

/// This Dao clss has to be overrided to use the CloudKit , it includes all the functions of a cloud datastore
public protocol CloudDAO{
    
    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void)
    
    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void)
    
    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void)
    
    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void)
    
    func fetchAllRecordZones(completionHandler: @escaping ([CKRecordZone]?, Error?) -> Void)
    
    func fetch(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone?, Error?) -> Void)
    
    func save(_ zone: CKRecordZone, completionHandler: @escaping (CKRecordZone?, Error?) -> Void)
    
    func delete(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone.ID?, Error?) -> Void)
    
    func fetchAllSubscriptions(completionHandler: @escaping ([CKSubscription]?, Error?) -> Void)
    
    func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, Error?) -> Void)
    
    func clear()
}
