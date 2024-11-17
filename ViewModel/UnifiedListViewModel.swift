////
////  UnifiedListViewModel.swift
////  TaqdaApp
////
////  Created by Rahaf ALghuraibi on 15/05/1446 AH.
////
//
//import Foundation
//import Foundation
//import SwiftUI
//import CloudKit
//import CoreML
//
//class UnifiedListViewModel: ObservableObject {
//    // MARK: - Published Properties
//    @Published var listName: String = ""
//    @Published var categories: [GroceryCategory] = []
//    @Published var items: [Item] = []
//    @Published var lists: [List] = [] // For managing fetched lists
//    @Published var currentListID: CKRecord.ID? // For the current list being worked on
//    @Published var userInput: String = "" // For product classification
//    @Published var isListComplete: Bool = false
//    @Published var isSharingAvailable: Bool = false
//    @Published var share: CKShare?
//    @Published var itemCount: Int = 0
//    @Published var isCreatingList: Bool = true // Flag to differentiate between creation and viewing contexts
//    @Published var listID: CKRecord.ID?
//    @Published var userSession: UserSession
//    @Published var createListViewModel: CreateListViewModel
//
//    // MARK: - Dependencies
//    private var database = CKContainer.default().publicCloudDatabase
//    private var model: MyFA13? = {
//        try? MyFA13(configuration: MLModelConfiguration())
//    }()
//
//    // MARK: - Initializer
//    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String, createListViewModel: CreateListViewModel) {
//          self.categories = categories
//          self.listID = listID
//          self.listName = listName
//          self.createListViewModel = createListViewModel
//      }
//
//    // MARK: - List Management
//    func fetchLists(completion: @escaping (Bool) -> Void) {
//        guard let userID = userSession.userID else {
//            print("User ID not available.")
//            completion(false)
//            return
//        }
//
//        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
//        let predicate = NSPredicate(format: "user_id == %@", userReference)
//        let query = CKQuery(recordType: "List", predicate: predicate)
//
//        database.perform(query, inZoneWith: nil) { [weak self] records, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error fetching lists: \(error.localizedDescription)")
//                    completion(false)
//                } else if let records = records {
//                    self?.lists = records.map { List(record: $0) }
//                    print("Fetched \(records.count) lists.")
//                    completion(true)
//                }
//            }
//        }
//    }
//
//    func saveListToCloudKit(completion: @escaping (CKRecord.ID?) -> Void) {
//        guard let userID = userSession.userID else {
//            print("User ID not available.")
//            completion(nil)
//            return
//        }
//
//        let newList = CKRecord(recordType: "List")
//        newList["list_name"] = listName as CKRecordValue
//        newList["created_at"] = Date() as CKRecordValue
//        newList["updated_at"] = Date() as CKRecordValue
//        newList["list_id"] = newList.recordID.recordName as CKRecordValue
//        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
//        newList["user_id"] = userReference
//
//        database.save(newList) { record, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error saving list: \(error.localizedDescription)")
//                    completion(nil)
//                } else if let record = record {
//                    print("List saved successfully with ID: \(record.recordID).")
//                    self.currentListID = record.recordID
//                    completion(record.recordID)
//                }
//            }
//        }
//    }
//
//    func deleteList() {
//        guard let listID = currentListID else { return }
//        database.delete(withRecordID: listID) { recordID, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error deleting list: \(error.localizedDescription)")
//                } else {
//                    print("List deleted successfully.")
//                }
//            }
//        }
//    }
//
//    // MARK: - Item Management
//    func fetchItems(for listID: CKRecord.ID, completion: @escaping (Bool) -> Void) {
//        let listReference = CKRecord.Reference(recordID: listID, action: .none)
//        let predicate = NSPredicate(format: "listId == %@", listReference)
//        let query = CKQuery(recordType: "Item", predicate: predicate)
//
//        database.perform(query, inZoneWith: nil) { [weak self] records, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error fetching items: \(error.localizedDescription)")
//                    completion(false)
//                } else if let records = records {
//                    self?.items = records.map { Item(record: $0) }
//                    print("Fetched \(records.count) items.")
//                    completion(true)
//                }
//            }
//        }
//    }
//
//    func saveItem(name: String, quantity: Int64, category: String, completion: @escaping (Bool) -> Void) {
//        guard let listID = currentListID else { return }
//
//        let listReference = CKRecord.Reference(recordID: listID, action: .none)
//        let newItem = Item(itemId: UUID(), nameItem: name, numberOfItem: quantity, listId: listReference, category: category)
//        let record = newItem.toRecord()
//
//        database.save(record) { record, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error saving item: \(error.localizedDescription)")
//                    completion(false)
//                } else {
//                    print("Item saved successfully.")
//                    completion(true)
//                }
//            }
//        }
//    }
//
//    // MARK: - Product Classification
//    func classifyProducts() {
//        guard let model = model else {
//            categories = [GroceryCategory(name: "Model not available", items: [])]
//            return
//        }
//
//        let processedInput = preprocessInput(userInput)
//        let productLines = processedInput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//        var categoryDict: [String: [GroceryItem]] = [:]
//
//        for product in productLines {
//            let correctedText = correctSpelling(for: product.lowercased())
//            let (quantity, productName) = extractQuantity(from: correctedText)
//
//            do {
//                let prediction = try model.prediction(text: productName)
//                let category = prediction.label
//                if categoryDict[category] == nil {
//                    categoryDict[category] = []
//                }
//                categoryDict[category]?.append(GroceryItem(name: productName, quantity: quantity))
//            } catch {
//                print("Prediction error: \(error)")
//            }
//        }
//
//        categories = categoryDict.map { GroceryCategory(name: $0.key, items: $0.value) }
//    }
//
//    // MARK: - Helper Functions
//    private func preprocessInput(_ input: String) -> String {
//        return input
//    }
//
//    private func correctSpelling(for text: String) -> String {
//        return text
//    }
//
//    private func extractQuantity(from text: String) -> (Int, String) {
//        return (1, text)
//    }
//}
