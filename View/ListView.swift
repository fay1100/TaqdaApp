import SwiftUI
import CloudKit
import UserNotifications
import TipKit // أضف المكتبة

struct ListView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @Environment(\.presentationMode) var presentationMode
    @State private var navigateToMainTab = false
    @ObservedObject private var viewModel: ListViewModel
    @State private var showAlert = false
    @State private var isNotificationPermissionGranted = false
    @State private var listID: CKRecord.ID?
    let addItemTip = AddItemTip()
    @ObservedObject private var createListViewModel: CreateListViewModel
    @State private var listName: String
    @State private var newItem: String = ""
    @State private var textFieldHeight: CGFloat = 40
    
    @EnvironmentObject var userSession: UserSession
    
    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String?, userSession: UserSession) {
        //        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: CreateListViewModel(userSession: userSession))
        self._listName = State(initialValue: listName ?? "")
        self.createListViewModel = CreateListViewModel(userSession: userSession)
        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: CreateListViewModel(userSession: userSession))
        print("Categories passed to ListView: \(categories)")
        
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
                    TextField("Enter Name", text: $createListViewModel.listName)                        .font(.system(size: 22, weight: .bold))
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
                    GroceryScrollView(viewModel: viewModel)
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
                            createListViewModel.saveListToCloudKit(userSession: createListViewModel.userSession, listName: createListViewModel.listName) { listID in
                                guard let listID = listID else { return }
                                
                                let listReference = CKRecord.Reference(recordID: listID, action: .deleteSelf)
                                
                                // تصنيف المنتجات قبل الحفظ
                                createListViewModel.classifyProducts()
                                
                                for category in createListViewModel.categorizedProducts {
                                    for item in category.items {
                                        // تحقق إذا كان العنصر موجودًا في التصنيف الحالي
                                        if let categoryIndex = viewModel.categories.firstIndex(where: { $0.name == category.name }),
                                           let itemIndex = viewModel.categories[categoryIndex].items.firstIndex(where: { $0.name.lowercased() == item.name.lowercased() }) {
                                            // إذا كان العنصر موجودًا، قم بزيادة الكمية
                                            DispatchQueue.main.async {
                                                viewModel.categories[categoryIndex].items[itemIndex].quantity += item.quantity
                                            }
                                            
                                            // تحديث العنصر في قاعدة البيانات
                                            createListViewModel.saveItem(
                                                name: item.name,
                                                quantity: Int64(viewModel.categories[categoryIndex].items[itemIndex].quantity),
                                                listId: listReference,
                                                category: category.name
                                            ) { success in
                                                if success {
                                                    print("Quantity updated for \(item.name)")
                                                }
                                            }
                                        } else {
                                            // إذا كان العنصر غير موجود، أضفه كعنصر جديد
                                            DispatchQueue.main.async {
                                                if let categoryIndex = viewModel.categories.firstIndex(where: { $0.name == category.name }) {
                                                    viewModel.categories[categoryIndex].items.append(item)
                                                } else {
                                                    // إضافة تصنيف جديد إذا لم يكن موجودًا
                                                    viewModel.categories.append(category)
                                                }
                                            }
                                            
                                            // حفظ العنصر الجديد في قاعدة البيانات
                                            createListViewModel.saveItem(
                                                name: item.name,
                                                quantity: Int64(item.quantity),
                                                listId: listReference,
                                                category: category.name
                                            ) { success in
                                                if success {
                                                    print("New item \(item.name) saved successfully.")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
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
    }}

struct ListView_Previews: PreviewProvider {
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

        ListView(categories: groceryItems, listID: mockListID, listName: mockListName, userSession: UserSession.shared)
            .environmentObject(UserSession.shared)
            .environment(\.layoutDirection, .rightToLeft)
            .previewLayout(.sizeThatFits)
    }
}
