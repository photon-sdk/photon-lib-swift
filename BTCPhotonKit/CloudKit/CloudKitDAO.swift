//
//  CloudKitDAO.swift
//  BTCPhotonKit
//
//  Created by Leon Johnson on 18/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

class CloudKitDAO:CloudDAO {
    var store = CKContainer.default().privateCloudDatabase

    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void){
        store.fetch(withRecordID: recordID, completionHandler: completionHandler)
    }

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void){
        store.save(record, completionHandler: completionHandler)
    }

    open func delete(withRecordID recordID:CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void){
        store.delete(withRecordID: recordID, completionHandler: completionHandler)
    }

    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void){
        store.perform(query,inZoneWith :zoneID,   completionHandler: completionHandler)
    }

    func fetchAllRecordZones(completionHandler: @escaping ([CKRecordZone]?, Error?) -> Void){
        store.fetchAllRecordZones(completionHandler: completionHandler)
    }

    func fetch(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone?, Error?) -> Void){
        store.fetch(withRecordZoneID: zoneID, completionHandler: completionHandler)

    }

    func save(_ zone: CKRecordZone, completionHandler: @escaping (CKRecordZone?, Error?) -> Void){
        store.save(zone, completionHandler: completionHandler)
    }

    func delete(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone.ID?, Error?) -> Void){
        store.delete(withRecordZoneID: zoneID, completionHandler: completionHandler)
    }

    open func fetchAllSubscriptions(completionHandler: @escaping ([CKSubscription]?, Error?) -> Void){
        store.fetchAllSubscriptions(completionHandler: completionHandler)
    }

    func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, Error?) -> Void){
        store.save(subscription, completionHandler: completionHandler)
    }

    func clear() {}

}
