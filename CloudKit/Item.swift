//
//  Item.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI
import CloudKit
import Combine

struct CategoryConstants {
    static let allCategories: [String] = [
        "meat, poultry",
        "seafood",
        "dairy",
        "fruits & vegetables",
        "frozen foods",
        "bakery",
        "rice, grains & pasta",
        "cooking and baking supplies",
        "deli",
        "spices & seasonings",
        "condiment & sauces",
        "canned food",
        "snacks, sweets & candy",
        "personal care products",
        "household supplies",
        "beverages & water",
        "coffee & tea",
        "breakfast foods",
        "baby products"
    ]
}



// MARK: - Item Model
struct Item {
    var recordID: CKRecord.ID?  // Optional record ID for CloudKit
    var itemId: UUID  // Unique identifier for the item
    var nameItem: String  // Name of the item
    var numberOfItem: Int64  // Quantity of the item
    var listId: CKRecord.Reference  // Reference to the associated list
    var category: String  // Category of the item

    // Convert the model to a CKRecord for saving to CloudKit
    func toRecord() -> CKRecord {
        let record = recordID != nil ? CKRecord(recordType: "Item", recordID: recordID!) : CKRecord(recordType: "Item")
        record["itemId"] = itemId.uuidString as CKRecordValue
        record["nameItem"] = nameItem as CKRecordValue
        record["numberOfItem"] = numberOfItem as CKRecordValue
        record["listId"] = listId
        record["category"] = category as CKRecordValue

        // Debug print to verify fields
        print("Converting to CKRecord - nameItem: \(nameItem), numberOfItem: \(numberOfItem), category: \(category)")

        return record
    }


    // Initialize the model from a CKRecord
    init(record: CKRecord) {
        self.recordID = record.recordID
        self.itemId = UUID(uuidString: record["itemId"] as? String ?? "") ?? UUID()  // Parse itemId as UUID from string
        self.nameItem = record["nameItem"] as? String ?? ""
        self.numberOfItem = record["numberOfItem"] as? Int64 ?? 0
        self.listId = record["listId"] as! CKRecord.Reference  // Force unwrap since listId is mandatory
        self.category = record["category"] as? String ?? ""
    }

    // Convenience initializer for creating new Items
    init(itemId: UUID = UUID(), nameItem: String, numberOfItem: Int64, listId: CKRecord.Reference, category: String) {
        self.recordID = nil
        self.itemId = itemId
        self.nameItem = nameItem
        self.numberOfItem = numberOfItem
        self.listId = listId
        self.category = category
    }
    
}



