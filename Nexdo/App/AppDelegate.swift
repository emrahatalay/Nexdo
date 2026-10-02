import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var quickCaptureController: QuickCaptureWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = QuickCaptureWindowController(modelContainer: AppEnvironment.shared.modelContainer)
        quickCaptureController = controller

        GlobalShortcutCenter.shared.requestInputMonitoringAccessIfNeeded()
        GlobalShortcutCenter.shared.start { [weak controller] in
            controller?.toggle()
        }

        let reminderHour = UserDefaults.standard.integer(forKey: AppSettingsKey.planningReminderHour)
        let reminderMinute = UserDefaults.standard.integer(forKey: AppSettingsKey.planningReminderMinute)
        NotificationService.shared.schedulePlanningReminder(hour: reminderHour, minute: reminderMinute)

        Task {
            await NotificationService.shared.requestAuthorizationIfNeeded()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalShortcutCenter.shared.stop()
    }
}
