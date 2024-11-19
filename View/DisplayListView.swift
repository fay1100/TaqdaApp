//
//  DisplayListView.swift
//  TaqdaApp
//
//  Created by Rahaf ALghuraibi on 17/05/1446 AH.
//

import SwiftUI
import CloudKit

struct DisplayListView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToMainTab = false
    @ObservedObject private var viewModel: ListViewModel
    @State private var showAlert = false
    @State private var isNotificationPermissionGranted = false
    @State private var listID: CKRecord.ID?
    @ObservedObject private var createListViewModel: CreateListViewModel
    @State private var listName: String
    @State private var newItem: String = ""
    @State private var textFieldHeight: CGFloat = 40
    let addItemTip = AddItemTip()
    @EnvironmentObject var userSession: UserSession
    
    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String?, userSession: UserSession) {
        //        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: CreateListViewModel(userSession: userSession))
        self._listName = State(initialValue: listName ?? "")
        self.createListViewModel = CreateListViewModel(userSession: userSession)
        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: CreateListViewModel(userSession: userSession))
    }
    var body: some View {
        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea()
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            
            Image("Background").resizable().ignoresSafeArea()
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss() // زر العودة للصفحة السابقة
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                                .resizable()
                                .frame(width: 7, height: 12)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    Spacer()
                    Text(listName)                 
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("PrimaryColor"))
                    
                    Spacer()
                    Menu {
                        Button(action: {
                            shareList()
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button(action: {
                            deleteListAndMoveToMain()
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            Image(systemName: "ellipsis")
                                .resizable()
                                .frame(width: 20, height: 4)
                                .foregroundColor(Color("PrimaryColor"))
                        }
                    }
                    
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                HStack {
                    Text("Items 🛒")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(Color("NameColor"))
                        .padding(.leading)
                    
                    Spacer()
                    
                    Menu {
                        //                        Button("In 10 Minutes", action: { scheduleReminder(interval: .tenMinutes) })
                        Button("Every Week", action: { scheduleReminder(interval: .weekly) })
                        Button("Every Two Weeks", action: { scheduleReminder(interval: .biweekly) })
                        Button("Every Three Weeks", action: { scheduleReminder(interval: .threeWeeks) })
                        Button("Every Month", action: { scheduleReminder(interval: .monthly) })
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color("CircleColor"))
                                .frame(width: 40, height: 40)
                            Image(systemName: "calendar.badge.clock")
                                .resizable()
                                .frame(width: 25, height: 25)
                                .foregroundColor(Color("PrimaryColor"))
                        }.padding(.trailing)
                    }
                    
                }
                .padding(.top, 15)
                
                ScrollView {
                    // for categories item
                    ForEach(viewModel.categories.indices, id: \.self) { categoryIndex in
                        let category = viewModel.categories[categoryIndex]
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Button(action: {
                                    viewModel.toggleCategorySelection(for: categoryIndex)
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(category.items.allSatisfy { $0.isSelected } ? Color("PrimaryColor") : Color.clear)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle().stroke(Color("PrimaryColor"), lineWidth: 2)
                                            )
                                        if category.items.allSatisfy({ $0.isSelected }) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                        }
                                    }.padding(.leading)
                                }
                                
                                Text(viewModel.formattedCategoryName(category.name))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(Color("NameColor"))
                                Spacer()
                            }
                            .padding(layoutDirection == .leftToRight ? .leading : .trailing)
                            
                            VStack(spacing: 0) {
                                // for assining each item into a suit category
                                ForEach(category.items.indices, id: \.self) { itemIndex in
                                    let item = category.items[itemIndex]
                                    
                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 18))
                                            .fontWeight(.medium)
                                            .strikethrough(item.isSelected, color: Color("Textlist"))
                                            .foregroundColor(Color("Textlist"))
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 10) {
                                            Button(action: {
                                                viewModel.decreaseQuantity(for: categoryIndex, itemIndex: itemIndex)
                                            }) {
                                                Image(systemName: "minus")
                                                    .foregroundColor(Color("gray1"))
                                                    .font(.system(size: 20))
                                            }
                                            
                                            Text("\(category.items[itemIndex].quantity)")
                                                .font(.title3)
                                                .frame(width: 18)
                                            
                                            Button(action: {
                                                viewModel.increaseQuantity(for: categoryIndex, itemIndex: itemIndex)
                                            }) {
                                                Image(systemName: "plus")
                                                    .foregroundColor(Color("NameColor"))
                                                    .font(.system(size: 20))
                                            }
                                        }
                                    }
                                    .padding()
                                    .background(Color("bakgroundTap"))
                                    .cornerRadius(8)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 75)
                                    .padding(.horizontal)
                                    
                                    
                                    if itemIndex != category.items.count - 1 {
                                        Divider()
                                            .padding(.horizontal)
                                    }
                                }
                            }
                            .background(Color("bakgroundtap"))
                            .cornerRadius(11)
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                }
                
                Spacer()
                
                VStack {
                    HStack(alignment: .center, spacing: 10) {
                        ExpandingTextField(
                            text: $createListViewModel.userInput,
                            dynamicHeight: $textFieldHeight, // تمرير dynamicHeight
                            placeholder: NSLocalizedString("write down your grocery", comment: "Prompt for the user to write their list")
                        )
                        //                        CustomTextField(text: $createListViewModel.userInput, placeholder: NSLocalizedString("write_down_your_list", comment: "Prompt for the user to write their list"))
                        .frame(height: textFieldHeight)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.white)
                        .cornerRadius(27)
                        .overlay(
                            RoundedRectangle(cornerRadius: 27)
                                .stroke(Color.gray, lineWidth: 0.1)
                        )
                        Button(action: {
                            updateList()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.2))
                                    .frame(width: 45, height: 45)
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color("PrimaryColor"))
                                    .font(.system(size: 20))
                            }
                        }
                        
                    }.popoverTip(addItemTip)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color("bakgroundtap"))
                                .ignoresSafeArea(edges: .bottom)
                        )
                        .padding(.horizontal)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .background(
            NavigationLink(
                destination: MainTabView()
                    .navigationBarBackButtonHidden(true),
                isActive: $navigateToMainTab,
                label: { EmptyView() }
            )
            .hidden()
        )
        
        
    }
    private func shareList() {
        let listContent = """
        List Name: \(listName)
        
        Items:
        \(viewModel.categories.flatMap { $0.items }.map { "- \($0.name) (\($0.quantity))" }.joined(separator: "\n"))
        """
        
        let activityViewController = UIActivityViewController(activityItems: [listContent], applicationActivities: nil)
        
        // لضمان عرض واجهة المشاركة بشكل صحيح:
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }
    private func deleteListAndMoveToMain() {
        guard let listID = viewModel.listID else { return }
        
        let database = CKContainer.default().publicCloudDatabase
        database.delete(withRecordID: listID) { _, error in
            if let error = error {
                print("Failed to delete list: \(error)")
            } else {
                DispatchQueue.main.async {
                    navigateToMainTab = true
                }
            }
        }
    }
    
    
    
    private func updateList() {
        guard let listID = viewModel.listID else {
            print("Error: No list ID available.")
            return
        }

        let listReference = CKRecord.Reference(recordID: listID, action: .deleteSelf)

        // تصنيف المنتجات قبل التحديث
        createListViewModel.classifyProducts()

        for category in createListViewModel.categorizedProducts {
            for item in category.items {
                if let categoryIndex = viewModel.categories.firstIndex(where: { $0.name.lowercased() == category.name.lowercased() }) {
                    // إذا كان التصنيف موجودًا
                    if let itemIndex = viewModel.categories[categoryIndex].items.firstIndex(where: { $0.name.lowercased() == item.name.lowercased() }) {
                        // إذا كان العنصر موجودًا، قم بتحديث الكمية
                        DispatchQueue.main.async {
                            viewModel.categories[categoryIndex].items[itemIndex].quantity += item.quantity
                        }

                        // تحديث العنصر في قاعدة البيانات
                        createListViewModel.updateItem(
                            name: item.name,
                            quantity: Int64(viewModel.categories[categoryIndex].items[itemIndex].quantity),
                            listId: listReference,
                            category: category.name
                        ) { success in
                            if success {
                                print("Updated quantity for \(item.name) in category \(category.name).")
                            } else {
                                print("Failed to update \(item.name).")
                            }
                        }
                    } else {
                        // إذا كان العنصر غير موجود في التصنيف، أضفه
                        DispatchQueue.main.async {
                            viewModel.categories[categoryIndex].items.append(item)
                        }

                        // حفظ العنصر الجديد في قاعدة البيانات
                        createListViewModel.saveItem(
                            name: item.name,
                            quantity: Int64(item.quantity),
                            listId: listReference,
                            category: category.name
                        ) { success in
                            if success {
                                print("Added new item \(item.name) to category \(category.name).")
                            } else {
                                print("Failed to save new item \(item.name).")
                            }
                        }
                    }
                } else {
                    // إذا كان التصنيف غير موجود، أضف تصنيفًا جديدًا
                    DispatchQueue.main.async {
                        viewModel.categories.append(category)
                    }

                    // حفظ العنصر الجديد مع التصنيف
                    createListViewModel.saveItem(
                        name: item.name,
                        quantity: Int64(item.quantity),
                        listId: listReference,
                        category: category.name
                    ) { success in
                        if success {
                            print("Added new category \(category.name) with item \(item.name).")
                        } else {
                            print("Failed to save category \(category.name) and item \(item.name).")
                        }
                    }
                }
            }
        }
    }


    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            completion(granted && error == nil)
        }
    }
    private func scheduleReminder(interval: ReminderInterval) {
        ReminderManager.shared.scheduleReminder(
            interval: interval,
            listName: listName
        ) { success in
            if success {
                print("Reminder set successfully.")
            } else {
                print("Failed to set reminder.")
            }
        }
    }
}


struct DisplayListView_Previews: PreviewProvider {
    static var previews: some View {
        let groceryItems: [GroceryCategory] = [
            GroceryCategory(name: "Bakery", items: [
                GroceryItem(name: "Bread", quantity: 2),
                GroceryItem(name: "Croissant", quantity: 5)
            ]),
            GroceryCategory(name: "Fruits & Vegetables", items: [
                GroceryItem(name: "Apple", quantity: 4),
                GroceryItem(name: "Banana", quantity: 3)
            ])
        ]
        
        let mockListID = CKRecord.ID(recordName: "mockRecordID")
        let mockListName = "Sample List"
        
        DisplayListView(categories: groceryItems, listID: mockListID, listName: mockListName, userSession: UserSession.shared)
            .environmentObject(UserSession.shared)
            .environment(\.layoutDirection, .rightToLeft)
            .previewLayout(.sizeThatFits)
    }
}

//#Preview {
//    DisplayListView()
//}
