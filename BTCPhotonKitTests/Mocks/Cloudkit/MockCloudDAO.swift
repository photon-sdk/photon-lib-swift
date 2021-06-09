//
//  MockCloudDAO.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 18/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit
@testable import BTCPhotonKit

class MockCloudDAO:CloudDAO {

    var store = MockCloudStore()

    func fetch(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        store.fetch(withRecordID: recordID,
                    completionHandler: completionHandler)

    }

    func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        store.save(record, completionHandler: completionHandler)
    }

    func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
        store.delete(withRecordID: recordID, completionHandler: completionHandler)

    }

    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {
        store.perform(query,inZoneWith: zoneID,completionHandler: completionHandler)

    }

    func fetchAllRecordZones(completionHandler: @escaping ([CKRecordZone]?, Error?) -> Void) {

    }

    func fetch(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone?, Error?) -> Void) {

    }

    func save(_ zone: CKRecordZone, completionHandler: @escaping (CKRecordZone?, Error?) -> Void) {

    }

    func delete(withRecordZoneID zoneID: CKRecordZone.ID, completionHandler: @escaping (CKRecordZone.ID?, Error?) -> Void) {

    }

    func fetchAllSubscriptions(completionHandler: @escaping ([CKSubscription]?, Error?) -> Void) {

    }

    func save(_ subscription: CKSubscription, completionHandler: @escaping (CKSubscription?, Error?) -> Void) {

    }

    public func clear() {
        store.clear()
    }

}
