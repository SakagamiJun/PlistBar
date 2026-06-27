import Foundation
import UserNotifications

enum NotificationService: Sendable {
    static func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
            return granted
        } catch {
            return false
        }
    }

    static func send(title: String, body: String, severity: LogRule.Severity) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = severity == .error ? .defaultCritical : .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}
