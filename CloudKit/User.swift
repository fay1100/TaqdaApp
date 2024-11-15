//
//  User.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI
import CloudKit
import Combine
// MARK: - User Model
struct User {
    var recordID: CKRecord.ID?
    var user_id: UUID
    var username: String
    var owner_id: [CKRecord.Reference] // Reference to lists owned by the user
    var shared_list: [CKRecord.Reference] // Reference to shared lists

    // Convert to CKRecord
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "User")
        record["user_id"] =  user_id.uuidString as CKRecordValue
        record["username"] = username as CKRecordValue
        record["owner_id"] = owner_id as CKRecordValue
        record["shared_list"] = shared_list as CKRecordValue
        return record
    }

    // Create from CKRecord
    init(record: CKRecord) {
        self.recordID = record.recordID
        self.user_id = UUID(uuidString: record["user_id"] as! String) ?? UUID()
        self.username = record["username"] as! String
        self.owner_id = record["owner_id"] as? [CKRecord.Reference] ?? []
        self.shared_list = record["shared_list"] as? [CKRecord.Reference] ?? []
    }
}
