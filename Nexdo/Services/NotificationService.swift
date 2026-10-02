import Foundation
import UserNotifications

/// Madde 24: bildirim sayısı düşük tutulur — sadece odak başlangıcı, zaman doluşu ve
/// akşam planlama hatırlatması.
@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private static let planningReminderIdentifier = "planningReminder"

    private init() {}

    /// `requestAuthorization` async olduğundan ana thread'i bloke etmez — `IOHIDRequestAccess`
    /// ile karıştırılmamalı (bkz. GlobalShortcutCenter).
    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    func notifyFocusStarted(taskTitle: String) {
        schedule(
            title: "Başladı",
            body: "\"\(taskTitle)\" için ayırdığın zaman başladı."
        )
    }

    func notifyTimeboxCompleted(minutes: Int) {
        schedule(
            title: "Zaman doldu",
            body: "\(minutes) dakikalık zaman kutun tamamlandı."
        )
    }

    func schedulePlanningReminder(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.planningReminderIdentifier])

        guard UserDefaults.standard.bool(forKey: AppSettingsKey.notificationsEnabled) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Yarını planlama zamanı"
        content.body = "Akşam Planı'nı açıp yarını hazırla."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.planningReminderIdentifier,
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelPlanningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.planningReminderIdentifier]
        )
    }

    private func schedule(title: String, body: String) {
        guard UserDefaults.standard.bool(forKey: AppSettingsKey.notificationsEnabled) else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
