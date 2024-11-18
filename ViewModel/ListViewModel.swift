//
//  ListViewModel.swift
//  TurboList
//
//  Created by Faizah Almalki on 02/05/1446 AH.
//

import Foundation
import SwiftUI
import CloudKit


class ListViewModel: ObservableObject {
    @Published var categories: [GroceryCategory]
      @Published var share: CKShare?
      @Published var isSharingAvailable: Bool = false
      @Published var items: [Item] = []
      @Published var itemCount: Int = 0
      @Published var listName: String = "Unnamed List"
      @Published var isListComplete: Bool = false
      @Published var currentListID: CKRecord.ID? = nil

    private var createListViewModel: CreateListViewModel

    // Properties for managing sharing
    public var listID: CKRecord.ID?
  
 
    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String?, createListViewModel: CreateListViewModel) {
        self.categories = categories
        self.listID = listID
        self.listName = listName ?? "Unnamed List"
        self.createListViewModel = createListViewModel
    }
    func refreshCategories(with newCategories: [GroceryCategory]) {
          DispatchQueue.main.async {
              self.categories = newCategories
          }
      }
    // Manage item quantities
    func increaseQuantity(for categoryIndex: Int, itemIndex: Int) {
        categories[categoryIndex].items[itemIndex].quantity += 1
    }
    
    func decreaseQuantity(for categoryIndex: Int, itemIndex: Int) {
        if categories[categoryIndex].items[itemIndex].quantity > 0 {
            categories[categoryIndex].items[itemIndex].quantity -= 1
        }
    }
    
    func toggleItemSelection(for categoryIndex: Int, itemIndex: Int) {
        categories[categoryIndex].items[itemIndex].isSelected.toggle()
        reorderCategories()
    }

    // Save all items using the `saveItem` function in `CreateListViewModel`
    func saveAllItems() {
        guard let listID = self.createListViewModel.currentListID else {
            print("No list ID available to associate items.")
            return
        }

        let listReference = CKRecord.Reference(recordID: listID, action: .deleteSelf)

        for category in categories {
            for item in category.items {
                createListViewModel.saveItem(
                    name: item.name,
                    quantity: Int64(item.quantity),
                    listId: listReference,
                    category: category.name
                ) { success in
                    if success {
                        print("Item '\(item.name)' saved successfully in ListViewModel.")
                    } else {
                        print("Failed to save item '\(item.name)' in ListViewModel.")
                    }
                }
            }
        }
    }

//    // Use `createShare` from `CreateListViewModel`
//    func shareList() {
//        createListViewModel.createShare()
//    }

    // Count the items using `countItems` in `CreateListViewModel`
    func countItems() {
        guard let listID = self.createListViewModel.currentListID else {
            print("No list ID available for counting items.")
            return
        }

        let listReference = CKRecord.Reference(recordID: listID, action: .none)
        createListViewModel.countItems(for: listReference) { itemCount in
            self.itemCount = itemCount
            print("Updated item count: \(self.itemCount)")
        }
    }

    // Delete the list and navigate to the main view
    func deleteListAndMoveToMain() {
        guard let listID = listID else {
            print("List ID is not available.")
            return
        }

        // Delete the list record from CloudKit
        CKContainer.default().publicCloudDatabase.delete(withRecordID: listID) { [weak self] recordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to delete list: \(error.localizedDescription)")
                } else {
                    print("List deleted successfully")
                    UIApplication.shared.windows.first?.rootViewController = UIHostingController(rootView: MainTabView())
                }
            }
        }
    }

    // Save list to favorites
    func saveToFavorites() {
        guard let listID = listID else { return }
        let recordID = CKRecord.ID(recordName: listID.recordName)
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: recordID) { record, error in
            if let record = record {
                record["isFavorite"] = true as CKRecordValue
                CKContainer.default().publicCloudDatabase.save(record) { savedRecord, error in
                    if let error = error {
                        print("Error saving to favorites: \(error)")
                    } else {
                        print("List saved to favorites")
                    }
                }
            } else if let error = error {
                print("Failed to fetch list for saving to favorites: \(error)")
            }
        }
    }
    func fetchItems(for listID: CKRecord.ID, completion: @escaping (Bool) -> Void) {
        // استخدام CloudKit container
        let database = CKContainer.default().publicCloudDatabase
        let listReference = CKRecord.Reference(recordID: listID, action: .none)
        let predicate = NSPredicate(format: "listId == %@", listReference)
        let query = CKQuery(recordType: "Item", predicate: predicate)

        database.perform(query, inZoneWith: nil) { [weak self] (records: [CKRecord]?, error: Error?) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching items: \(error.localizedDescription)")
                    completion(false)
                } else if let records = records {
                    print("Records fetched: \(records.count) items found.")
                    
                    // تحويل السجلات إلى عناصر وتصنيفها
                    let fetchedItems = records.map { Item(record: $0) }
                    
                    // تأكد من أن الخاصية 'categorizedProducts' موجودة أو استخدم خاصية صحيحة
                    self?.categories = self?.categorizeItems(fetchedItems) ?? []
                    
                    print("Mapped items: \(fetchedItems)")
                    completion(true)
                } else {
                    print("No records found.")
                    completion(false)
                }
            }
            if let records = records {
                print("Records fetched: \(records.count) items found.")
                let fetchedItems = records.map { Item(record: $0) }
                self?.categories = self?.categorizeItems(fetchedItems) ?? []
                print("Mapped items: \(fetchedItems)")
                completion(true)
            }
        }
    }





    private func categorizeItems(_ items: [Item]) -> [GroceryCategory] {
        // Group items by their category
        var categoryDict: [String: [GroceryItem]] = [:]
        
        for item in items {
            // Map `Item` to `GroceryItem`
            let groceryItem = GroceryItem(
                name: item.nameItem,
                quantity: Int(item.numberOfItem),
                isSelected: false // Assuming default state
            )
            categoryDict[item.category, default: []].append(groceryItem)
        }

        // Convert the dictionary into an array of GroceryCategory objects
        return categoryDict.map { GroceryCategory(name: $0.key, items: $0.value) }
    }



    // Reorder categories
    private func reorderCategories() {
        let completedCategories = categories.filter { category in
            category.items.allSatisfy { $0.isSelected }
        }
        let incompleteCategories = categories.filter { category in
            !category.items.allSatisfy { $0.isSelected }
        }
        categories = incompleteCategories + completedCategories
    }

    // Utility function to format category names for display
    func formattedCategoryName(_ name: String) -> String {
        let languageCode = Locale.current.languageCode
        
        switch name {
        case "Meat, Poultry":
            return languageCode == "ar" ? "لحوم ودواجن 🥩" : "Meat & Poultry 🥩"
        case "Seafood":
            return languageCode == "ar" ? "مأكولات بحرية 🦐" : "Seafood 🦐"
        case "Dairy":
            return languageCode == "ar" ? "منتجات الألبان 🧀" : "Dairy 🧀"
        case "Fruits & Vegetables":
            return languageCode == "ar" ? "فواكه وخضروات 🍇" : "Fruits & Vegetables 🍇"
        case "Frozen Foods":
            return languageCode == "ar" ? "أطعمة مجمدة ❄️" : "Frozen Foods ❄️"
        case "Bakery":
            return languageCode == "ar" ? "مخبوزات 🍞" : "Bakery 🍞"
        case "Rice, Grains & Pasta":
            return languageCode == "ar" ? "أرز وحبوب ومعكرونة 🌾" : "Rice, Grains & Pasta 🌾"
        case "Cooking and Baking Supplies":
            return languageCode == "ar" ? "مستلزمات الطهي والخبز 🍲" : "Cooking and Baking Supplies 🍲"
        case "Deli":
            return languageCode == "ar" ? "مأكولات معدة 🥓" : "Deli 🥓"
        case "Spices & Seasonings":
            return languageCode == "ar" ? "التوابل والمنكهات 🧂" : "Spices & Seasonings 🧂"
        case "Sondiment & Sauces":
            return languageCode == "ar" ? "صلصات وتوابل 🍝" : "Condiment & Sauces 🍝"
        case "Canned Food":
            return languageCode == "ar" ? "أطعمة معلبة 🥫" : "Canned Food 🥫"
        case "Snacks, Sweets & Candy":
            return languageCode == "ar" ? "وجبات خفيفة وحلويات 🍭" : "Snacks, Sweets & Candy 🍭"
        case "Personal Care Products":
            return languageCode == "ar" ? "منتجات العناية الشخصية 🧴" : "Personal Care Products 🧴"
        case "Household Supplies":
            return languageCode == "ar" ? "مستلزمات منزلية 🧹" : "Household Supplies 🧹"
        case "Beverages & Water":
            return languageCode == "ar" ? "مشروبات ومياه 💧" : "Beverages & Water 💧"
        case "coffee tea":
            return languageCode == "ar" ? "قهوة وشاي ☕️" : "Coffee and Tea ☕️"
        case "Breakfast Foods":
            return languageCode == "ar" ? "أطعمة الإفطار 🥞" : "Breakfast Foods 🥞"
        case "Baby Products":
            return languageCode == "ar" ? "منتجات الأطفال 🍼" : "Baby Products 🍼"
        default:
            return name
        }
    }
    
//    var isListComplete: Bool {
//        categories.allSatisfy { category in
//            category.items.allSatisfy { $0.isSelected }
//        }
//    }
    func toggleCategorySelection(for categoryIndex: Int) {
        let allSelected = categories[categoryIndex].items.allSatisfy { $0.isSelected }
        categories[categoryIndex].items.indices.forEach { itemIndex in
            categories[categoryIndex].items[itemIndex].isSelected = !allSelected
        }
        reorderCategories()
    }

}



//
//extension ListViewModel {
//    private var database: CKDatabase {
//        return CKContainer.default().privateCloudDatabase
//    }
//
//    // Fetch all lists from CloudKit
//    func fetchListsFromCloudKit() {
//        let query = CKQuery(recordType: "List", predicate: NSPredicate(value: true))
//
//        database.perform(query, inZoneWith: nil) { records, error in
//            DispatchQueue.main.async {
//                if let records = records {
//                    self.categories = records.map { record in
//                        // Assuming you want to categorize items by list name
//                        let listName = record["list_name"] as! String
//                        let items = self.fetchItemsForList(listId: record.recordID)
//                        return GroceryCategory(name: listName, items: items)
//                    }
//                } else if let error = error {
//                    print("Error fetching lists: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    // Fetch items for a specific list
//    func fetchItemsForList(listId: CKRecord.ID) -> [GroceryItem] {
//        // Add logic to fetch items based on the listId from CloudKit
//        // Placeholder logic for now
//        return [
//            GroceryItem(name: "Placeholder Item", quantity: 1)  // Example item
//        ]
//    }
//
//    // Save a new list to CloudKit
//    func saveListToCloudKit(_ list: List) {
//        let record = list.toRecord()
//
//        database.save(record) { savedRecord, error in
//            DispatchQueue.main.async {
//                if let savedRecord = savedRecord {
//                    let newList = List(record: savedRecord)
//                    let newCategory = GroceryCategory(name: newList.listName, items: [])
//                    self.categories.append(newCategory)
//                    print("save list ")
//                } else if let error = error {
//                    print("Error saving list: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//
//    // Update an existing list in CloudKit
//    func updateListInCloudKit(_ list: List) {
//        guard let recordID = list.recordID else { return }
//
//        database.fetch(withRecordID: recordID) { fetchedRecord, error in
//            if let fetchedRecord = fetchedRecord {
//                fetchedRecord["list_name"] = list.listName as CKRecordValue
//                fetchedRecord["isShared"] = list.isShared as CKRecordValue
//                fetchedRecord["updated_at"] = Date() as CKRecordValue
//
//                self.database.save(fetchedRecord) { updatedRecord, error in
//                    DispatchQueue.main.async {
//                        if let updatedRecord = updatedRecord {
//                            if let index = self.categories.firstIndex(where: { $0.name == list.listName }) {
//                               // self.categories[index].name = list.listName
//                            }
//                        } else if let error = error {
//                            print("Error updating list: \(error.localizedDescription)")
//                        }
//                    }
//                }
//            } else if let error = error {
//                print("Error fetching list to update: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    // Delete a list from CloudKit
//    func deleteListFromCloudKit(_ list: List) {
//        guard let recordID = list.recordID else { return }
//
//        database.delete(withRecordID: recordID) { deletedRecordID, error in
//            DispatchQueue.main.async {
//                if let deletedRecordID = deletedRecordID {
//                    self.categories.removeAll { $0.name == list.listName }
//                } else if let error = error {
//                    print("Error deleting list: \(error.localizedDescription)")
//                }
//            }
//        }
//    }
//    // Save a new list to CloudKit
//      func saveListToCloudKit(listName: String, isShared: Bool) {
//          let newList = CKRecord(recordType: "List")
//          newList["list_name"] = listName as CKRecordValue
//          newList["isShared"] = isShared as CKRecordValue
//          newList["created_at"] = Date() as CKRecordValue
//          newList["updated_at"] = Date() as CKRecordValue
//
//          database.save(newList) { record, error in
//              DispatchQueue.main.async {
//                  if let record = record {
//                      print("List saved successfully with name: \(listName)")
//                      // Optionally update local list if needed
//                  } else if let error = error {
//                      print("Error saving list: \(error.localizedDescription)")
//                  }
//              }
//          }
//      }
//}
//
