//
//  CreateListViewModel.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
//
//  CreateListViewModel.swift
//  TurboList
//
//  Created by Faizah Almalki on 02/05/1446 AH.
//


import Foundation
import SwiftUI
import CoreML

import CloudKit
import AuthenticationServices
class CreateListViewModel: ObservableObject {
    @Published var share: CKShare?
    @Published var isSharingAvailable: Bool = false
    @Published var isBellTapped: Bool = false
    @Published var listName: String = ""
    @Published var userInput: String = ""
    @Published var categorizedProducts: [GroceryCategory] = []
    @Published var showResults: Bool = false {
         didSet {
             print("showResults updated to: \(showResults)")
         }
     }
    private var database = CKContainer.default().publicCloudDatabase
      @Published var items: [Item] = []
      @Published var sharedLists: [SharedList] = []
    @Published var currentListID: CKRecord.ID? // Store the current list ID
//    @Published var share: CKShare?
//    @Published var isSharingAvailable: Bool = false
    @Published var lists: [List] = [] // Store fetched lists here
   
    var userSession: UserSession // Store the user session
    // Initializer that accepts a UserSession
       init(userSession: UserSession) {
           self.userSession = userSession
          
           // Any additional setup
       }



    private var model: MyFA13? = {
        do {
            return try MyFA13(configuration: MLModelConfiguration())
        } catch {
            print("Failed to load model: \(error)")
            return nil
        }
    }()

    func classifyProducts() {
        guard let model = model else {
            categorizedProducts = [GroceryCategory(name: "Model not available", items: [])]
            return
        }
        
        // فصل المنتجات بناءً على الأسطر
        let lines = userInput.split(separator: "\n")
        var products: [String] = []
        
        for line in lines {
            // تقسيم بناءً على الفاصلة سواء كانت عربية أو إنجليزية
            let lineProducts = line.split { $0 == "," || $0 == "،" }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            products.append(contentsOf: lineProducts)
        }
        
        var categoryDict: [String: [GroceryItem]] = [:]
        
        for product in products {
            let correctedText = correctSpelling(for: product.lowercased())
            let (quantity, productName) = extractQuantity(from: correctedText)
            
            do {
                let prediction = try model.prediction(text: productName)
                let category = prediction.label
                
                if categoryDict[category] != nil {
                    categoryDict[category]?.append(GroceryItem(name: productName, quantity: quantity))
                } else {
                    categoryDict[category] = [GroceryItem(name: productName, quantity: quantity)]
                }
            } catch {
                print("Prediction error: \(error)")
                if categoryDict["Prediction Error"] != nil {
                    categoryDict["Prediction Error"]?.append(GroceryItem(name: productName, quantity: quantity))
                } else {
                    categoryDict["Prediction Error"] = [GroceryItem(name: productName, quantity: quantity)]
                }
            }
        }
        
        // تحويل النتائج إلى مصفوفة من GroceryCategory
        categorizedProducts = categoryDict.map { GroceryCategory(name: $0.key, items: $0.value) }
    }


    private func preprocessInputWithNLP(_ input: String) -> String {
        var processedText = input
        processedText = correctSpelling(for: processedText)
        processedText = removeStopWords(processedText)
        processedText = normalizeUnitsAndQuantities(processedText)
        return processedText
    }
    
    private func extractQuantity(from text: String) -> (Int, String) {
        // تحويل الأرقام العربية إلى أرقام لاتينية
        var normalizedText = normalizeNumbers(in: text)

        // قائمة الأرقام بالكلمات باللغتين العربية والإنجليزية
        let numberWords: [String: Int] = [
            "one": 1, "two": 2, "three": 3, "four": 4, "five": 5,
            "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
            "eleven": 11, "twelve": 12, "thirteen": 13, "fourteen": 14,
            "fifteen": 15, "sixteen": 16, "seventeen": 17, "eighteen": 18,
            "nineteen": 19, "twenty": 20, "thirty": 30, "forty": 40, "fifty": 50,
            "sixty": 60, "seventy": 70, "eighty": 80, "ninety": 90, "hundred": 100,
            
            
                "واحد": 1, "واحده": 1,
                "اثنين": 2, "إثنين": 2,
                "ثلاثة": 3, "ثلاثه": 3,
                "اربعة": 4, "أربعة": 4, "اربع": 4, "أربع": 4,
                "خمسة": 5, "خمس": 5, "خمسه": 5,
                "ستة": 6, "سته": 6,
                "سبعة": 7, "سبعه": 7,
                "ثمانية": 8, "ثمانيه": 8, "ثمان": 8, "ثماني": 8,
                "تسعة": 9, "تسعه": 9,
                "عشرة": 10, "عشره": 10, "عشر": 10,
                "احد عشر": 11, "أحد عشر": 11, "احدعشر": 11, "أحدعشر": 11,
                "اثنا عشر": 12, "إثنا عشر": 12, "اثناعشر": 12, "إثناعشر": 12,
                "ثلاثة عشر": 13, "ثلاثه عشر": 13, "ثلاثةعشر": 13, "ثلاثهعشر": 13,
                "اربعة عشر": 14, "أربعة عشر": 14, "اربع عشر": 14, "أربع عشر": 14, "اربعه عشر": 14, "أربعه عشر": 14,
                "خمسة عشر": 15, "خمسه عشر": 15, "خمس عشر": 15, "خمسعشر": 15,
                "ستة عشر": 16, "سته عشر": 16,
                "سبعة عشر": 17, "سبعه عشر": 17,
                "ثمانية عشر": 18, "ثمانيه عشر": 18,
                "تسعة عشر": 19, "تسعه عشر": 19,
                "عشرون": 20, "عشرين": 20,
                "ثلاثون": 30, "ثلاثين": 30,
                "اربعون": 40, "أربعون": 40, "اربعين": 40, "أربعين": 40,
                "خمسون": 50, "خمسين": 50,
                "ستون": 60, "ستين": 60,
                "سبعون": 70, "سبعين": 70,
                "ثمانون": 80, "ثمانين": 80,
                "تسعون": 90, "تسعين": 90,
                "مائة": 100, "مئة": 100
            

        ]
        
        // التحقق من وجود كلمة رقمية في النص واستبدالها
        for (word, number) in numberWords {
            if normalizedText.contains(word) {
                normalizedText = normalizedText.replacingOccurrences(of: word, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                return (number, normalizedText)
            }
        }
        
        // تحويل الأرقام العربية إلى لاتينية
        let arabicToLatinNumbers: [Character: Character] = [
            "٠": "0", "١": "1", "٢": "2", "٣": "3", "٤": "4",
            "٥": "5", "٦": "6", "٧": "7", "٨": "8", "٩": "9"
        ]
        normalizedText = String(normalizedText.map { arabicToLatinNumbers[$0] ?? $0 })
        
        // استخراج الأرقام الرقمية
        let numericParts = normalizedText.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let quantity = Int(numericParts), quantity > 0 {
            normalizedText = normalizedText.replacingOccurrences(of: numericParts, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            return (quantity, normalizedText)
        }
        
        // القيمة الافتراضية للكمية هي 1
        return (1, normalizedText)
    }


    private func normalizeNumbers(in text: String) -> String { text }
    private func correctSpelling(for text: String) -> String { text }
    private func removeStopWords(_ text: String) -> String {
        let stopWords = ["please", "the", "a", "an", "and", "of", "on", "in", "at", "for", "with", "about", "against", "between", "into", "through", "during", "before", "after", "above", "below", "to", "from", "up", "down", "out", "over", "under"]
        
        let pattern = "\\b(" + stopWords.joined(separator: "|") + ")\\b"
        let regex = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let newText = regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        
        return newText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func normalizeUnitsAndQuantities(_ text: String) -> String {
        var newText = text
        let unitMappings = ["kg": "kg", "liter": "L"]
        for (englishUnit, standardUnit) in unitMappings {
            newText = newText.replacingOccurrences(of: englishUnit, with: standardUnit)
        }
        return newText
    }
}



extension CreateListViewModel {
    // Fetch all lists from CloudKit and store them in a published array
    func fetchLists(completion: @escaping (Bool) -> Void) {
        guard let userID = userSession.userID else {
            print("User ID is not available.")
            completion(false)
            return
        }

        let userReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        let predicate = NSPredicate(format: "user_id == %@", userReference)
        let query = CKQuery(recordType: "List", predicate: predicate)

        database.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching lists: \(error.localizedDescription)")
                    completion(false)
                } else if let records = records {
                    self?.lists = records.map { List(record: $0) }  // Ensure lists is updated here
                    print("Successfully fetched \(records.count) lists.")
                    completion(true)
                }
            }
        }
    }





    // Fetch items for a specific list and store them in the `items` array
//    func fetchItems(for listID: CKRecord.ID, completion: @escaping (Bool) -> Void) {
//        let listReference = CKRecord.Reference(recordID: listID, action: .none)
//        let predicate = NSPredicate(format: "list_id == %@", listReference)
//        let query = CKQuery(recordType: "Item", predicate: predicate)
//
//        database.perform(query, inZoneWith: nil) { [weak self] records, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("Error fetching items: \(error.localizedDescription)")
//                    completion(false)
//                } else if let records = records {
//                    // Map the fetched records to `Item` instances
//                    self?.items = records.map { Item(record: $0) }  // Assuming `Item` has an initializer for `CKRecord`
//                    print("Successfully fetched \(records.count) items for list ID \(listID).")
//                    completion(true)
//                }
//            }
//        }
//    }
    
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
//                    print("Records fetched: \(records)")
//                    // Map the fetched records to `Item` instances
//                    self?.items = records.map { Item(record: $0) }
//                    print("Successfully fetched \(records.count) items for list ID \(listID).")
//                    print("Mapped items: \(self?.items ?? [])")
//                    completion(true)
//                } else {
//                    print("No records found and no error received.")
//                    completion(false)
//                }
//            }
//        }
//    }
    
}

extension CreateListViewModel {
    func attemptToSaveListToCloudKit(userSession: UserSession, listName: String, completion: @escaping (CKRecord.ID?) -> Void) {
        guard let userID = userSession.userID else {
            print("Error: User ID is not available.")
            completion(nil)
            return
        }
        
        // Pass the listName to saveListToCloudKit
        saveListToCloudKit(userSession: userSession, listName: listName, completion: completion)
    }

 
    func saveListWithConfirmation(listName: String, completion: @escaping (CKRecord.ID?) -> Void) {
        userSession.getUserID { success in
            if success {
                // Now that userID is confirmed, call saveListToCloudKit
                self.saveListToCloudKit(userSession: self.userSession, listName: listName) { recordID in
                    if let recordID = recordID {
                        print("List saved successfully with ID: \(recordID)")
                        completion(recordID)
                    } else {
                        print("Failed to save list.")
                        completion(nil)
                    }
                }
            } else {
                print("User ID could not be set.")
                completion(nil)
            }
        }
    }
    func saveSharedListToCloudKit(sharedListId: UUID, ownerId: CKRecord.Reference, listId: CKRecord.Reference, completion: @escaping (Bool) -> Void) {
        let sharedListRecord = CKRecord(recordType: "SharedList")
        sharedListRecord["sharedListId"] = sharedListId.uuidString as CKRecordValue
        sharedListRecord["ownerId"] = ownerId
        sharedListRecord["listId"] = listId
        
        CKContainer.default().publicCloudDatabase.save(sharedListRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving shared list record: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Shared list record saved successfully.")
                    completion(true)
                }
            }
        }
    }

    func saveUserRecord(userSession: UserSession, username: String, completion: @escaping (Bool) -> Void) {
        guard let userID = userSession.userID else {
            print("Error: User ID is not available.")
            completion(false)
            return
        }
        
        let userRecord = CKRecord(recordType: "User")
        userRecord["user_id"] = userID as CKRecordValue
        userRecord["username"] = username as CKRecordValue
        
        CKContainer.default().publicCloudDatabase.save(userRecord) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving user record: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("User record saved successfully.")
                    completion(true)
                }
            }
        }
    }

    func saveListToCloudKit(userSession: UserSession, listName: String, completion: @escaping (CKRecord.ID?) -> Void) {
        guard let userID = userSession.userID else {
            print("Error: User ID is not available.")
            completion(nil)
            return
        }
        
        // Create a new record of type "List"
        let newList = CKRecord(recordType: "List")
        
        // Set the fields for the list record
        newList["list_name"] = listName as CKRecordValue
        newList["isShared"] = false as CKRecordValue
        newList["created_at"] = Date() as CKRecordValue
        newList["updated_at"] = Date() as CKRecordValue
        newList["list_total_item"] = 0 as CKRecordValue
        newList["list_id"] = newList.recordID.recordName as CKRecordValue
        
        // Create the user reference for `user_id` field
        let ownerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: userID), action: .none)
        newList["user_id"] = ownerReference // Set the ownerId reference

        print("Saving record with list_name: \(listName), ownerId: \(ownerReference)")
        
        // Save the new record to CloudKit
        CKContainer.default().publicCloudDatabase.save(newList) { record, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving list: \(error.localizedDescription)")
                    completion(nil)
                } else if let record = record {
                    print("List saved successfully with ID: \(record.recordID)")
                    completion(record.recordID)
                }
            }
        }
    }


    func countItems(for listReference: CKRecord.Reference, completion: @escaping (Int) -> Void) {
          let predicate = NSPredicate(format: "list_id == %@", listReference)
          let query = CKQuery(recordType: "Item", predicate: predicate)

          CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
              DispatchQueue.main.async {
                  if let error = error {
                      print("Error counting items: \(error.localizedDescription)")
                      completion(0)
                  } else {
                      let itemCount = records?.count ?? 0
                      print("Number of items in list: \(itemCount)")
                      completion(itemCount)
                  }
              }
          }
      }
    func saveItemsAndCount(listReference: CKRecord.Reference) {
        var itemCount = 0
        let totalItems = categorizedProducts.flatMap { $0.items }.count

        for category in categorizedProducts {
            for item in category.items {
                // Pass category.name directly as the `category` argument
                saveItem(name: item.name, quantity: Int64(item.quantity), listId: listReference, category: category.name) { success in
                    if success {
                        itemCount += 1
                        // Update list count after the last item is saved
                        if itemCount == totalItems {
                            self.updateListCount(listReference.recordID, count: itemCount)
                        }
                    }
                }
            }
        }
    }

    func saveItem(name: String, quantity: Int64, listId: CKRecord.Reference, category: String, completion: @escaping (Bool) -> Void) {
        let newItem = Item(itemId: UUID(), nameItem: name, numberOfItem: quantity, listId: listId, category: category)

        // Debug print
        print("Saving item - nameItem: \(newItem.nameItem), numberOfItem: \(newItem.numberOfItem), category: \(newItem.category)")

        let record = newItem.toRecord()

        // Verify CKRecord fields
        print("CKRecord fields - nameItem: \(record["nameItem"] ?? ""), numberOfItem: \(record["numberOfItem"] ?? ""), category: \(record["category"] ?? "")")

        CKContainer.default().publicCloudDatabase.save(record) { savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving item: \(error.localizedDescription)")
                    completion(false)
                } else if let savedRecord = savedRecord {
                    print("Item '\(name)' saved successfully with recordID: \(savedRecord.recordID)")
                    completion(true)
                }
            }
        }
    }


    func updateListCount(_ listID: CKRecord.ID, count: Int) {
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: listID) { record, error in
            if let record = record {
                record["list_total_item"] = count as CKRecordValue
                CKContainer.default().publicCloudDatabase.save(record) { _, error in
                    if let error = error {
                        print("Error updating list count: \(error)")
                    } else {
                        print("List item count updated successfully.")
                    }
                }
            } else if let error = error {
                print("Error fetching list for update: \(error)")
            }
        }
    }

//    func createShare() {
//        guard let listID = currentListID else {
//            print("No list ID available for sharing.")
//            return
//        }
//
//        CKContainer.default().publicCloudDatabase.fetch(withRecordID: listID) { [weak self] record, error in
//            guard let record = record else {
//                print("Error fetching record: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//
//            let share = CKShare(rootRecord: record)
//            share[CKShare.SystemFieldKey.title] = self?.listName as CKRecordValue?
//            share.publicPermission = .readWrite // Ensure this is set correctly
//
//            let operation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
//            operation.savePolicy = .allKeys
//
//            operation.modifyRecordsCompletionBlock = { savedRecords, deletedRecordIDs, error in
//                if let error = error {
//                    print("Error creating share: \(error.localizedDescription)")
//                    if let ckError = error as? CKError {
//                        print("CKError Code: \(ckError.code.rawValue)")
//                        print("CKError UserInfo: \(ckError.userInfo)")
//                    }
//                } else {
//                    print("Successfully created share with records: \(String(describing: savedRecords))")
//                }
//            }
//
//            CKContainer.default().publicCloudDatabase.add(operation)
//        }
//    }




}
