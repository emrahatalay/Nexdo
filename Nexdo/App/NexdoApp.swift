import SwiftData
import SwiftUI

@main
struct NexdoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(environment.modelContainer)

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
