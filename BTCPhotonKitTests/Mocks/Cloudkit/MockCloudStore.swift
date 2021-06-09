//
//  MockCloudStore.swift
//  BTCPhotonKitTests
//
//  Created by Leon Johnson on 18/05/21.
//  Copyright © 2021 Leon Johnson. All rights reserved.
//

import Foundation
import CloudKit

class MockCloudStore {

    var items = [CKRecord]()

    func fetch(withRecordID recordID: CKRecord.ID,
               completionHandler: @escaping (CKRecord?, Error?) -> Void){
        let filteredItems = items.filter { $0.recordID == recordID }
        if let record = filteredItems.first{
            completionHandler(record,nil)
        }else{
            completionHandler(nil,ClodMockError(message: "Unknown ID"))
        }
    }

     func save(_ record: CKRecord, completionHandler: @escaping (CKRecord?, Error?) -> Void) {
        items.append(record)
            completionHandler(record,nil)
    }

     func delete(withRecordID recordID: CKRecord.ID, completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {

        let filteredItems = items.filter { $0.recordID == recordID }
        if let record = filteredItems.first{
            guard let index = items.firstIndex(of: record) else {
                completionHandler(nil,ClodMockError(message: "Error"))
                return
            }
            self.items.remove(at: index)
            completionHandler(record.recordID,nil)
        }
    }

    func perform(_ query: CKQuery, inZoneWith zoneID: CKRecordZone.ID?, completionHandler: @escaping ([CKRecord]?, Error?) -> Void) {

        let filteredItems = items.filter { $0.recordType == query.recordType }
        completionHandler(filteredItems,nil)

    }

     func clear(){
        items.removeAll()
    }
}

struct ClodMockError: Error,LocalizedError {
    let message: String
    var errorDescription: String? {
        return message
    }
}
