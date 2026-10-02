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
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalShortcutCenter.shared.stop()
    }
}
