import SwiftUI
import CloudKit
import UserNotifications

struct ListView: View {
    @Environment(\.layoutDirection) var layoutDirection
    @State private var navigateToMainTab = false
    @ObservedObject private var viewModel: ListViewModel
    @State private var showAlert = false
    @State private var isNotificationPermissionGranted = false

    @ObservedObject private var createListViewModel: CreateListViewModel
    @State private var listName: String
    @State private var newItem: String = ""
    @State private var textFieldHeight: CGFloat = 40

    @EnvironmentObject var userSession: UserSession

    init(categories: [GroceryCategory], listID: CKRecord.ID?, listName: String?, userSession: UserSession) {
        self.viewModel = ListViewModel(categories: categories, listID: listID, listName: listName, createListViewModel: CreateListViewModel(userSession: userSession))
        self._listName = State(initialValue: listName ?? "")
        self.createListViewModel = CreateListViewModel(userSession: userSession)
    }

    var body: some View {
        ZStack {
            Color("backgroundApp")
                .ignoresSafeArea()
            Image("Background").resizable().ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: {
                        if viewModel.isListComplete {
                            navigateToMainTab = true
                        } else {
                            showAlert = true
                        }
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
                    TextField("Enter Name", text: $listName)
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color("PrimaryColor"))
                    Spacer()
                    Menu {
                        Button(action: {
                            viewModel.saveToFavorites()
                        }) {
                            Label("Favorite", systemImage: "heart")
                        }
                        Button(action: {
                            viewModel.deleteListAndMoveToMain()
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
                        ExpandingTextField(text: $newItem, dynamicHeight: $textFieldHeight, placeholder: "Enter Your Grocery ")
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
                            addNewItem()
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
                    }
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
    }

    private func addNewItem() {
        guard !listName.isEmpty else {
            print("List name is required.")
            return
        }

        createListViewModel.saveListToCloudKit(userSession: userSession, listName: listName) { success in
            if let success = success { // Check if the optional value is not nil
                print("List saved successfully with ID: \(success.recordName).")
            } else {
                print("Failed to save the list.")
            }
        }


        // Clear input fields
        newItem = ""
    }

    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            completion(granted && error == nil)
        }
    }

    private func scheduleReminder(interval: ReminderInterval) {
        if !isNotificationPermissionGranted {
            requestNotificationPermission { granted in
                if granted {
                    isNotificationPermissionGranted = true
                    createReminder(interval: interval)
                }
            }
        } else {
            createReminder(interval: interval)
        }
    }

    private func createReminder(interval: ReminderInterval) {
        let content = UNMutableNotificationContent()

        let languageCode = Locale.preferredLanguages.first ?? "en"

        if languageCode.starts(with: "ar") {
            content.title = "شَطبة"
            content.body = "حان وقت التسوق! تحقق من قائمتك اليوم."
        } else {
            content.title = "Shaṭba"
            content.body = "It's shopping time! Check your list today."
        }

        content.sound = UNNotificationSound.default

        let trigger: UNNotificationTrigger
        switch interval {
        case .weekly:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 604800, repeats: true)
        case .biweekly:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1209600, repeats: true)
        case .threeWeeks:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1814400, repeats: true)
        case .monthly:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2419200, repeats: true)
        }

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}



enum ReminderInterval {
    case weekly, biweekly, threeWeeks, monthly
}
struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock data for testing
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

