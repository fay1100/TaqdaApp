//
//  CloudKitManager.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import Foundation


import CloudKit

class CloudKitManager {
    let container = CKContainer(identifier: "iCloud.FaizahApp")
    let publicDB = CKContainer.default().publicCloudDatabase

    // Save record to CloudKit
    func saveRecord(record: CKRecord, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        publicDB.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            }
        }
    }

    func fetchRecords(recordType: String, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        publicDB.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(results ?? []))
            }
        }
    }


    func addList(list: List, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = list.toRecord()
        saveRecord(record: record, completion: completion)
    }

    func addItem(item: Item, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = item.toRecord()
        saveRecord(record: record, completion: completion)
    }


    func fetchUserLists(user: User, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let predicate = NSPredicate(format: "owned_id == %@", user.recordID!)
        let query = CKQuery(recordType: "List", predicate: predicate)
        publicDB.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(results ?? []))
            }
        }
    }

}
