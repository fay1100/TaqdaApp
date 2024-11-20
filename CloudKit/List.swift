//
//  List.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI
import CloudKit
import Combine

// MARK: - List Model
struct List {
    var recordID: CKRecord.ID?
    var listId: UUID
    var listName: String
    var isShared: Bool // خاصية تحدد ما إذا كانت القائمة مشتركة
    var ownedId: CKRecord.Reference // Reference to the user who owns the list
    var createdAt: Date
    var updatedAt: Date
    var totalItems: Int64
    var isFavorite: Bool = false  // Default value for isFavorite

    // Convert the model to a CKRecord for saving to CloudKit
    func toRecord() -> CKRecord {
        let record = recordID != nil ? CKRecord(recordType: "List", recordID: recordID!) : CKRecord(recordType: "List")
        
        record["list_id"] = listId.uuidString as CKRecordValue  // Store UUID as a String
        record["list_name"] = listName as CKRecordValue
        record["isShared"] = isShared as CKRecordValue
        record["owned_id"] = ownedId
        record["created_at"] = createdAt as CKRecordValue
        record["updated_at"] = updatedAt as CKRecordValue
        record["list_total_item"] = totalItems as CKRecordValue
        record["isFavorite"] = isFavorite ? 1 : 0

        return record
    }

    // Initialize the model from a CKRecord
    init(record: CKRecord) {
        self.recordID = record.recordID
        self.listId = UUID(uuidString: record["list_id"] as? String ?? "") ?? UUID()  // Parse list_id as UUID from String
        self.listName = record["list_name"] as? String ?? ""
        self.isShared = record["isShared"] as? Bool ?? false

        // Safely unwrap owned_id
        if let ownerRef = record["owned_id"] as? CKRecord.Reference {
            self.ownedId = ownerRef
        } else {
            print("Warning: owned_id is missing or is not a CKReference.")
            // Provide a default CKRecord.Reference with a known recordName for testing or fallback purposes
            self.ownedId = CKRecord.Reference(recordID: CKRecord.ID(recordName: "default_owner_id"), action: .none)
        }
        
        self.createdAt = record["created_at"] as? Date ?? Date()
        self.updatedAt = record["updated_at"] as? Date ?? Date()
        self.totalItems = record["list_total_item"] as? Int64 ?? 0
        self.isFavorite = (record["isFavorite"] as? Int64 ?? 0) == 1
    }

    // Convenience initializer for creating a new List
    init(listId: UUID = UUID(), listName: String, isShared: Bool = false, ownedId: CKRecord.Reference, createdAt: Date = Date(), updatedAt: Date = Date(), totalItems: Int64 = 0, isFavorite: Bool = false) {
        self.listId = listId
        self.listName = listName
        self.isShared = isShared
        self.ownedId = ownedId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.totalItems = totalItems
        self.isFavorite = isFavorite
    }
}
func updateFavoriteStatus(for list: List, isFavorite: Bool, completion: @escaping (Bool) -> Void) {
    guard let recordID = list.recordID else {
        print("No recordID found for the list.")
        completion(false)
        return
    }

    let database = CKContainer.default().publicCloudDatabase
    database.fetch(withRecordID: recordID) { record, error in
        guard let record = record, error == nil else {
            print("Failed to fetch record: \(error?.localizedDescription ?? "Unknown error")")
            completion(false)
            return
        }

        record["isFavorite"] = isFavorite ? 1 : 0 // تحديث القيمة
        database.save(record) { _, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save record: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Favorite status updated successfully.")
                    completion(true)
                }
            }
        }
    }
}


