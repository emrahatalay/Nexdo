import AppKit
import Foundation

/// Tüm kullanıcı tercihleri `UserDefaults` üzerinde — bunlar domain verisi değil, uygulama
/// yapılandırması (Madde 28). Servisler (View olmayan sınıflar) `@AppStorage` kullanamadığından
/// anahtarlar burada merkezi olarak tutulur.
enum AppSettingsKey {
    static let defaultTimeboxMinutes = "settings.defaultTimeboxMinutes"
    static let extensionMinutes = "settings.extensionMinutes"
    static let dailyAvailableMinutes = "settings.dailyAvailableMinutes"
    static let defaultBufferMinutes = "settings.defaultBufferMinutes"
    static let planningReminderHour = "settings.planningReminderHour"
    static let planningReminderMinute = "settings.planningReminderMinute"
    static let notificationsEnabled = "settings.notificationsEnabled"
    static let appearance = "settings.appearance"
    static let quickCaptureKeyCode = "settings.quickCaptureKeyCode"
    static let quickCaptureModifiers = "settings.quickCaptureModifiers"
    static let quickCaptureDisplayString = "settings.quickCaptureDisplayString"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            defaultTimeboxMinutes: 25,
            extensionMinutes: 15,
            dailyAvailableMinutes: 360,
            defaultBufferMinutes: 45,
            planningReminderHour: 21,
            planningReminderMinute: 30,
            notificationsEnabled: true,
            appearance: AppAppearance.system.rawValue,
            quickCaptureKeyCode: 49,
            quickCaptureModifiers: Int(NSEvent.ModifierFlags([.command, .shift]).rawValue),
            quickCaptureDisplayString: "⌘⇧Space"
        ])
    }
}
