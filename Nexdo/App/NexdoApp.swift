import SwiftData
import SwiftUI

@main
struct NexdoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let environment = AppEnvironment.shared

    @AppStorage(AppSettingsKey.appearance) private var appearanceRawValue = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(AppAppearance(rawValue: appearanceRawValue)?.colorScheme)
        }
        .modelContainer(environment.modelContainer)
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Bugün") {
                    AppEnvironment.shared.navigationState.selection = .today
                }
                .keyboardShortcut("2", modifiers: .command)

                Button("İş Havuzu") {
                    AppEnvironment.shared.navigationState.selection = .inbox
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Akşam Planı") {
                    AppEnvironment.shared.navigationState.selection = .planning
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
        }

        MenuBarExtra {
            MenuBarPopoverView()
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.window)
    }
}
