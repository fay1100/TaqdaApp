import SwiftUI
import Combine
import UserNotifications
import CloudKit

struct CreateListView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection
    @StateObject private var viewModel: CreateListViewModel
    @EnvironmentObject var userSession: UserSession
    @State private var newListName: String = ""
    @State private var isCreatingNewList = false
    @State private var isNotificationPermissionGranted = false  // متغير لتخزين حالة إذن الإشعارات

    init(userSession: UserSession) {
        _viewModel = StateObject(wrappedValue: CreateListViewModel(userSession: userSession))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color("backgroundAppColor")
                    .ignoresSafeArea()
                Image("Background")
                    .resizable()
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Button(action: { dismiss() }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isBellTapped ? Color("MainColor") : Color("GreenLight"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: layoutDirection == .rightToLeft ? "chevron.right" : "chevron.left")
                                    .resizable()
                                    .frame(width: 7, height: 12)
                                    .foregroundColor(viewModel.isBellTapped ? .white : Color("MainColor"))
                            }
                        }

                        Spacer()

                        TextField("Enter list name", text: $viewModel.listName)
                            .font(.system(size: 20, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Spacer()

                        NavigationLink(
                            destination: ListView(
                                categories: viewModel.categorizedProducts,
                                listID: viewModel.currentListID,
                                listName: viewModel.listName,
                                createListViewModel: viewModel
                            ),
                            isActive: $viewModel.showResults
                        ) {
                            Button(action:{
                                viewModel.saveListToCloudKit(userSession: viewModel.userSession, listName: viewModel.listName) { listID in
                                    guard let listID = listID else { return }
                             
                                    let listReference = CKRecord.Reference(recordID: listID, action: .deleteSelf)
                                    viewModel.classifyProducts()

                                    for category in viewModel.categorizedProducts {
                                        for item in category.items {
                                            viewModel.saveItem(
                                                name: item.name,
                                                quantity: Int64(item.quantity),
                                                listId: listReference,
                                                category: category.name
                                            ) { success in
                                                if success {
                                                    print("Item '\(item.name)' saved successfully in CreateListViewModel.")
                                                } else {
                                                    print("Failed to save item '\(item.name)'.")
                                                }
                                            }
                                        }
                                    }
                                    viewModel.showResults = true
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(viewModel.isBellTapped ? Color("MainColor") : Color("GreenLight"))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "checkmark")
                                        .resizable()
                                        .frame(width: 17, height: 18)
                                        .foregroundColor(viewModel.isBellTapped ? .white : Color("MainColor"))
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 30)

                    HStack {
                        Text("Items 🛒")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(Color("GreenC"))
                        
                        Spacer()
                        
                        Menu {
                            Button("Every Week", action: { scheduleReminder(interval: .weekly) })
                            Button("Every Two Weeks", action: { scheduleReminder(interval: .biweekly) })
                            Button("Every Three Weeks", action: { scheduleReminder(interval: .threeWeeks) })
                            Button("Every Month", action: { scheduleReminder(interval: .monthly) })
//                            Button("In 10 seconds", action: { scheduleReminder(interval: .seconds(10)) })
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(viewModel.isBellTapped ? Color("MainColor") : Color("GreenLight"))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "calendar.badge.clock")
                                    .resizable()
                                    .frame(width: 30, height: 25)
                                    .foregroundColor(viewModel.isBellTapped ? .white : Color("MainColor"))
                                    .padding(.trailing, -5)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)

                    ScrollView {
                        CustomTextField(text: $viewModel.userInput, placeholder: NSLocalizedString("write_down_your_list", comment: "Prompt for the user to write their list"))
                            .frame(width: 350, height: 650)
                            .cornerRadius(11.5)
                    }
                    .ignoresSafeArea(.keyboard)
                    
                    Spacer()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCreateListView)) { notification in
            if let items = notification.object as? [GroceryItem], let listName = notification.userInfo?["listName"] as? String {
                viewModel.listName = listName
                viewModel.userInput = items.map { "\($0.quantity) x \($0.name)" }.joined(separator: ", ")
                viewModel.showResults = false
            }
        }
    }
    
    private func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Notification permission granted: \(granted)")
                completion(granted)
            }
        }
    }

    private func scheduleReminder(interval: ReminderInterval) {
        // طلب الإذن إذا لم يكن قد تم منحه سابقًا
        if !isNotificationPermissionGranted {
            requestNotificationPermission { granted in
                if granted {
                    self.isNotificationPermissionGranted = true
                    self.createReminder(interval: interval)
                }
            }
        } else {
            createReminder(interval: interval)
        }
    }
    private func createReminder(interval: ReminderInterval) {
        print("Scheduling reminder...")

        let content = UNMutableNotificationContent()
        
        // تحديد اللغة المفضلة للجهاز
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        
        // ضبط نص التذكير حسب اللغة
        if languageCode == "ar" {
            content.title = "شَطبة"
            content.body = "حان وقت التسوق! تحقق من قائمتك اليوم"
        } else {
            content.title = "شَطبة"
            content.body = "Shopping time! Check on your list today"
        }
        
        content.sound = UNNotificationSound.default

        let trigger: UNNotificationTrigger
        switch interval {
        case .weekly:
            var dateComponents = DateComponents()
            dateComponents.weekday = Calendar.current.component(.weekday, from: Date())
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
        case .biweekly:
            var dateComponents = DateComponents()
            dateComponents.weekday = Calendar.current.component(.weekday, from: Date())
            dateComponents.weekOfYear = (Calendar.current.component(.weekOfYear, from: Date()) + 2) % 52
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
        case .threeWeeks:
            var dateComponents = DateComponents()
            dateComponents.weekOfYear = (Calendar.current.component(.weekOfYear, from: Date()) + 3) % 52
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
        case .monthly:
            var dateComponents = DateComponents()
            dateComponents.day = Calendar.current.component(.day, from: Date())
            trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            
        case .seconds(let intervalSeconds):
            print("Scheduling reminder in \(intervalSeconds) seconds")
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: intervalSeconds, repeats: false)
        }

        let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule reminder: \(error.localizedDescription)")
            } else {
                print("Reminder scheduled successfully.")
            }
        }
    }

}

// Enum to define reminder intervals
enum ReminderInterval {
    case weekly, biweekly, threeWeeks, monthly
    case seconds(TimeInterval)
}

extension Notification.Name {
    static let navigateToCreateListView = Notification.Name("navigateToCreateListView")
}

struct CreateListView_Previews: PreviewProvider {
    static var previews: some View {
        CreateListView(userSession: UserSession.shared)
            .environmentObject(UserSession.shared)
    }
}
