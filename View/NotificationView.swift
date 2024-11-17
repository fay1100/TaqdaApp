import SwiftUI

struct NotificationItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let message: String
    let date: Date
}





struct NotificationView: View {
    @State private var notifications: [NotificationItem] = []
    @Environment(\.dismiss) var dismiss
    @Environment(\.layoutDirection) var layoutDirection

    var body: some View {
        NavigationStack {
            ZStack {
                Color("backgroundApp")
                    .ignoresSafeArea()

                VStack {
                    // Header
                    HStack {
                        Button(action: {
                            dismiss()
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

                        Text("Notification")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color("GreenDark"))

                        Spacer()
                    }
                    .padding(.leading, 20)
                    .padding(.top, 10)

                    Spacer()

                    Rectangle()
                        .fill(Color("bakgroundtap"))
                        .cornerRadius(11, corners: [.topLeft, .topRight])
                        .overlay(
                            RoundedRectangle(cornerRadius: 11)
                                .stroke(Color("strokeColor"), lineWidth: 2)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(
                            ScrollView {
                                VStack(spacing: 15) {
                                    if notifications.isEmpty {
                                        Text("No Notifications")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 16, weight: .medium))
                                    } else {
                                        ForEach(notifications) { notification in
                                            HStack(spacing: 12) {
                                                Image(systemName: "bell.badge.circle")
                                                    .resizable()
                                                    .frame(width: 32, height: 32)
                                                    .foregroundColor(Color("PrimaryColor"))

                                                VStack(alignment: .leading) {
                                                    Text(notification.title)
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(Color("titleColor"))

                                                    Text(notification.message)
                                                        .font(.system(size: 12))
                                                        .foregroundColor(Color.gray)
                                                }

                                                Spacer()
                                            }
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 10)

                                            Divider()
                                                .background(Color("strokeColor"))
                                        }
                                    }
                                }
                                .padding()
                            }
                        )
                }
            }
        }
        .onAppear {
            loadNotificationsFromLocal()
            setupNotificationDelegate()
        }
        .navigationBarBackButtonHidden(true)
    }

    // تعيين الـ delegate للإشعارات
    func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = NotificationCenterDelegate { notification in
            DispatchQueue.main.async {
                notifications.append(notification)
                saveNotificationsToLocal()
            }
        }
    }

    // حفظ الإشعارات محليًا
    func saveNotificationsToLocal() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: "notificationsKey")
        } catch {
            print("Failed to save notifications: \(error.localizedDescription)")
        }
    }

    // تحميل الإشعارات المخزنة
    func loadNotificationsFromLocal() {
        do {
            if let data = UserDefaults.standard.data(forKey: "notificationsKey") {
                let decoder = JSONDecoder()
                let loadedNotifications = try decoder.decode([NotificationItem].self, from: data)
                notifications = loadedNotifications
            }
        } catch {
            print("Failed to load notifications: \(error.localizedDescription)")
        }
    }
}

// Delegate لمعالجة الإشعارات
class NotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
    var onReceiveNotification: ((NotificationItem) -> Void)

    init(onReceiveNotification: @escaping (NotificationItem) -> Void) {
        self.onReceiveNotification = onReceiveNotification
    }

    // يتم استدعاء هذه الدالة عند تسليم الإشعار
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let content = notification.request.content
        let newNotification = NotificationItem(
            id: UUID(),
            title: content.title,
            message: content.body,
            date: Date()
        )
        onReceiveNotification(newNotification)
        completionHandler([.sound, .banner]) // عرض الإشعار في النظام
    }
}
#Preview {
    NotificationView()
}
