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

struct Item {
    var itemId: UUID
    var nameItem: String
    var numberOfItem: Int64
    var listId: CKRecord.Reference
    var category: String  // Changed from categories array to a single category string
    func toRecord() -> CKRecord {
        let record = CKRecord(recordType: "Item")
        record["itemId"] = itemId.uuidString as CKRecordValue // Use UUID as a string
        record["nameItem"] = nameItem as CKRecordValue
        record["numberOfItem"] = numberOfItem as CKRecordValue
        record["listId"] = listId // Ensure listId is CKRecord.Reference

        record["category"] = category as CKRecordValue
        return record
    }

    init(record: CKRecord) {
        self.itemId = UUID(uuidString: record["itemId"] as? String ?? "") ?? UUID() // Parse itemId as UUID from String
        self.nameItem = record["nameItem"] as? String ?? ""
        self.numberOfItem = record["numberOfItem"] as? Int64 ?? 0
        self.listId = record["listId"] as! CKRecord.Reference
        self.category = record["category"] as? String ?? ""
    }


    // Convenience initializer for new Items (no CKRecord yet)
    init(itemId: UUID = UUID(), nameItem: String, numberOfItem: Int64, listId: CKRecord.Reference, category: String) {
        self.itemId = itemId
        self.nameItem = nameItem
        self.numberOfItem = numberOfItem
        self.listId = listId
        self.category = category
    }
}
