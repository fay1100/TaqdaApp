//
//  ReminderManager.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 17/05/1446 AH.
//

import Foundation
import UserNotifications

enum ReminderInterval {
    case tenMinutes, weekly, biweekly, threeWeeks, monthly
}

struct NotificationItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let message: String
    let date: Date
}

class ReminderManager {
    static let shared = ReminderManager()

    private init() {}

    // خاصية لتتبع حالة الإذن بالإشعارات
    private var isPermissionGranted = false

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            completion(granted && error == nil)
        }
    }

    func scheduleReminder(
        interval: ReminderInterval,
        listName: String,
        completion: @escaping (Bool) -> Void
    ) {
        // تحقق من حالة الإذن
        if !isPermissionGranted {
            requestNotificationPermission { granted in
                DispatchQueue.main.async {
                    self.isPermissionGranted = granted
                    if granted {
                        self.createReminder(interval: interval, listName: listName, completion: completion)
                    } else {
                        completion(false)
                    }
                }
            }
        } else {
            createReminder(interval: interval, listName: listName, completion: completion)
        }
    }

    private func createReminder(
        interval: ReminderInterval,
        listName: String,
        completion: @escaping (Bool) -> Void
    ) {
        let content = UNMutableNotificationContent()
        content.title = listName.isEmpty ? "تقضى" : listName

        let languageCode = Locale.preferredLanguages.first ?? "en"
        content.body = languageCode.starts(with: "ar") ?
            "حان وقت التسوق! تحقق من قائمتك اليوم." :
            "It's shopping time! Check your list today."

        content.sound = UNNotificationSound.default

        let trigger: UNNotificationTrigger
        switch interval {
        case .tenMinutes:
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
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

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Notification scheduled successfully for \(listName).")
                completion(true)
            }
        }
    }

    func saveNotification(_ notification: NotificationItem) {
        do {
            var notifications = loadNotifications()
            notifications.append(notification)
            let encoder = JSONEncoder()
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: "notificationsKey")
        } catch {
            print("Failed to save notification: \(error.localizedDescription)")
        }
    }

    func loadNotifications() -> [NotificationItem] {
        do {
            if let data = UserDefaults.standard.data(forKey: "notificationsKey") {
                let decoder = JSONDecoder()
                return try decoder.decode([NotificationItem].self, from: data)
            }
        } catch {
            print("Failed to load notifications: \(error.localizedDescription)")
        }
        return []
    }
}
