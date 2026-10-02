import SwiftUI

/// Madde 28: General, Focus, Planning, Notifications, Shortcuts, Appearance.
/// "Routines" bölümü spec'te listelense de somut bir ayar önermiyor — boş bir sekme
/// eklemek yerine (Madde 54: placeholder bırakma) kapsam dışında tutuldu.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("Genel", systemImage: "gearshape") }

            FocusSettingsTab()
                .tabItem { Label("Odak", systemImage: "scope") }

            PlanningSettingsTab()
                .tabItem { Label("Planlama", systemImage: "moon.stars") }

            NotificationsSettingsTab()
                .tabItem { Label("Bildirimler", systemImage: "bell") }

            ShortcutsSettingsTab()
                .tabItem { Label("Kısayollar", systemImage: "keyboard") }

            AppearanceSettingsTab()
                .tabItem { Label("Görünüm", systemImage: "paintbrush") }
        }
        .frame(minWidth: 520, idealWidth: 680, maxWidth: 820, minHeight: 420, idealHeight: 520, maxHeight: 720)
        .background(AppBackground())
    }
}

private struct GeneralSettingsTab: View {
    @State private var launchAtLogin = LaunchAtLoginManager.isEnabled
    var body: some View {
        Form {
            Toggle("Girişte Başlat", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLoginManager.setEnabled(newValue)
                }
        }
        .padding(AppSpacing.large)
    }
}

private struct FocusSettingsTab: View {
    @AppStorage(AppSettingsKey.defaultTimeboxMinutes) private var defaultTimeboxMinutes = 25
    @AppStorage(AppSettingsKey.extensionMinutes) private var extensionMinutes = 15

    var body: some View {
        Form {
            Stepper("Varsayılan Timebox: \(defaultTimeboxMinutes) dk", value: $defaultTimeboxMinutes, in: 5...180, step: 5)
            Stepper("Uzatma Süresi: \(extensionMinutes) dk", value: $extensionMinutes, in: 5...60, step: 5)
        }
        .padding(AppSpacing.large)
    }
}

private struct PlanningSettingsTab: View {
    @AppStorage(AppSettingsKey.dailyAvailableMinutes) private var dailyAvailableMinutes = 360
    @AppStorage(AppSettingsKey.defaultBufferMinutes) private var defaultBufferMinutes = 45
    @AppStorage(AppSettingsKey.planningReminderHour) private var reminderHour = 21
    @AppStorage(AppSettingsKey.planningReminderMinute) private var reminderMinute = 30

    var body: some View {
        Form {
            Stepper(
                "Günlük Kullanılabilir Süre: \(dailyAvailableMinutes / 60) sa \(dailyAvailableMinutes % 60) dk",
                value: $dailyAvailableMinutes, in: 60...720, step: 15
            )
            Stepper("Varsayılan Tampon: \(defaultBufferMinutes) dk", value: $defaultBufferMinutes, in: 0...180, step: 15)

            DatePicker(
                "Planlama Hatırlatma Saati",
                selection: reminderTimeBinding,
                displayedComponents: .hourAndMinute
            )
            .onChange(of: reminderHour) { _, _ in rescheduleReminder() }
            .onChange(of: reminderMinute) { _, _ in rescheduleReminder() }
        }
        .padding(AppSpacing.large)
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminderHour, minute: reminderMinute, second: 0, of: .now) ?? .now
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = components.hour ?? reminderHour
                reminderMinute = components.minute ?? reminderMinute
            }
        )
    }

    private func rescheduleReminder() {
        NotificationService.shared.schedulePlanningReminder(hour: reminderHour, minute: reminderMinute)
    }
}

private struct NotificationsSettingsTab: View {
    @AppStorage(AppSettingsKey.notificationsEnabled) private var notificationsEnabled = true

    var body: some View {
        Form {
            Toggle("Bildirimleri Etkinleştir", isOn: $notificationsEnabled)
                .onChange(of: notificationsEnabled) { _, isEnabled in
                    if isEnabled {
                        let hour = UserDefaults.standard.integer(forKey: AppSettingsKey.planningReminderHour)
                        let minute = UserDefaults.standard.integer(forKey: AppSettingsKey.planningReminderMinute)
                        NotificationService.shared.schedulePlanningReminder(hour: hour, minute: minute)
                    } else {
                        NotificationService.shared.cancelPlanningReminder()
                    }
                }
            Text("Odak başlangıcı, zaman doluşu ve akşam planlama hatırlatması için kullanılır.")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.large)
    }
}

private struct ShortcutsSettingsTab: View {
    var body: some View {
        Form {
            ShortcutRecorderView()

            Section {
                shortcutRow("Odağa Başla", "⌘ Return")
                shortcutRow("Bitti (Odak içinde)", "⌘⇧ Return")
                shortcutRow("Duraklat / Devam Et", "Space")
            }
        }
        .padding(AppSpacing.large)
    }

    private func shortcutRow(_ label: String, _ shortcut: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut)
                .foregroundStyle(.secondary)
        }
    }
}

private struct AppearanceSettingsTab: View {
    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue

    var body: some View {
        Form {
            Picker("Görünüm", selection: $appearanceRawValue) {
                ForEach(AppAppearance.allCases, id: \.rawValue) { option in
                    Text(option.title).tag(option.rawValue)
                }
            }
            .pickerStyle(.radioGroup)
        }
        .padding(AppSpacing.large)
    }
}
