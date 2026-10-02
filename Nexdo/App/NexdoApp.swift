import SwiftData
import SwiftUI

@main
struct NexdoApp: App {
    private let environment = AppEnvironment.shared

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(environment.modelContainer)

        Settings {
            SettingsView()
        }
    }
}
