//
//  SharedList.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//
import Foundation
import CloudKit

// MARK: - SharedList Model
struct SharedList: Identifiable {
    var id: UUID { sharedListId }  // Use sharedListId as the unique identifier
    var sharedListId: UUID  // Unique identifier for the shared list
    var ownerId: CKRecord.Reference  // Reference to the owner of the shared list
    var listId: CKRecord.Reference  // Reference to the associated list

    // Convert the model to a CKRecord for saving to CloudKit
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "SharedList")
        record["shared_list_id"] = sharedListId.uuidString as CKRecordValue  // Store UUID as a string
        record["ownerId"] = ownerId  // Reference to the owner
        record["listId"] = listId  // Reference to the associated list
        return record
    }

    // Initialize the model from a CKRecord
    init(record: CKRecord) {
        self.sharedListId = UUID(uuidString: record["shared_list_id"] as? String ?? "") ?? UUID()
        
        // Safely unwrap ownerId
        if let ownerRef = record["ownerId"] as? CKRecord.Reference {
            self.ownerId = ownerRef
        } else {
            print("Error: ownerId is missing or not a CKReference.")
            self.ownerId = CKRecord.Reference(recordID: CKRecord.ID(recordName: "default_owner_id"), action: .none)
        }

        // Safely unwrap listId
        if let listRef = record["listId"] as? CKRecord.Reference {
            self.listId = listRef
        } else {
            print("Error: listId is missing or not a CKReference. Actual value: \(String(describing: record["listId"]))")
            self.listId = CKRecord.Reference(recordID: CKRecord.ID(recordName: "default_list_id"), action: .none)
        }
    }

    // Convenience initializer for creating a new SharedList
    init(sharedListId: UUID = UUID(), ownerId: CKRecord.Reference, listId: CKRecord.Reference) {
        self.sharedListId = sharedListId
        self.ownerId = ownerId
        self.listId = listId
    }
    
}
