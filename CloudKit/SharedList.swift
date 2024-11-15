//
//  SharedList.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI
import CloudKit
import Combine
struct SharedList: Identifiable {
    var id: UUID { sharedListId } // Use sharedListId as the identifier
    var sharedListId: UUID
    var ownerId: CKRecord.Reference
    var listId: CKRecord.Reference
    init(record: CKRecord) {
        self.sharedListId = UUID(uuidString: record["shared_list_id"] as? String ?? "") ?? UUID()

        if let ownerRef = record["ownerId"] as? CKRecord.Reference {
            self.ownerId = ownerRef
        } else {
            print("Error: ownerId is not a CKReference.")
            self.ownerId = CKRecord.Reference(recordID: CKRecord.ID(recordName: "default_owner_id"), action: .none)
        }

        if let listRef = record["listId"] as? CKRecord.Reference {
            self.listId = listRef
        } else {
            // Log the actual value of listId to help identify why it's not a CKReference
            print("Error: listId is not a CKReference. Actual value: \(String(describing: record["listId"]))")
            self.listId = CKRecord.Reference(recordID: CKRecord.ID(recordName: "default_list_id"), action: .none)
        }
    }



    // Convenience initializer for new SharedList (no CKRecord yet)
    init(sharedListId: UUID = UUID(), ownerId: CKRecord.Reference, listId: CKRecord.Reference) {
        self.sharedListId = sharedListId
        self.ownerId = ownerId
        self.listId = listId
    }
}
