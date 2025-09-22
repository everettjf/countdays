import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notifications granted: \(granted)")
            }
        }
    }

    func scheduleCountdownReminder(for entry: Entry) {
        guard entry.entryType == .countDown, let targetDate = entry.targetDate else { return }
        let content = UNMutableNotificationContent()
        content.title = entry.title
        content.body = "Today is the day!"
        content.sound = .default

        var triggerDate = Calendar.current.dateComponents([.year, .month, .day], from: targetDate)
        triggerDate.hour = 8
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: entry.id.uuidString, content: content, trigger: trigger)
        center.add(request) { error in
            if let error = error {
                print("Notification scheduling failed: \(error)")
            }
        }
    }

    func cancelReminder(for entry: Entry) {
        center.removePendingNotificationRequests(withIdentifiers: [entry.id.uuidString])
    }
}
