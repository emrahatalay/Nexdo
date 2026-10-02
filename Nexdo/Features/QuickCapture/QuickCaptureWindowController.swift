import AppKit
import SwiftData
import SwiftUI

/// Quick Capture panelini barındıran borderless, floating `NSPanel`.
/// SwiftUI'nin `Window` scene'i global kısayolla tetiklenen, odaksız-açılabilen
/// bir palet için yeterli kontrolü sağlamadığından AppKit kullanılıyor.
@MainActor
final class QuickCaptureWindowController: NSWindowController, NSWindowDelegate {
    private let modelContext: ModelContext

    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 88),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        super.init(window: panel)

        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: QuickCapturePanel(modelContext: modelContext, onDismiss: { [weak self] in
                self?.hide()
            })
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    func toggle() {
        guard let panel = window else { return }
        if panel.isVisible {
            hide()
        } else {
            show()
        }
    }

    private func show() {
        guard let panel = window, let screen = NSScreen.main else { return }
        let origin = NSPoint(
            x: screen.visibleFrame.midX - panel.frame.width / 2,
            y: screen.visibleFrame.midY - panel.frame.height / 2 + screen.visibleFrame.height * 0.15
        )
        panel.setFrameOrigin(origin)
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func hide() {
        window?.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
