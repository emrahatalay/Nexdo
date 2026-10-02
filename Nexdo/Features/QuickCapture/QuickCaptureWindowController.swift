import AppKit
import SwiftData
import SwiftUI

private final class QuickCaptureWindow: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class QuickCaptureWindowController: NSWindowController, NSWindowDelegate {
    private let modelContext: ModelContext
    private let presentationState = QuickCapturePresentationState()

    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)

        let panel = QuickCaptureWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 108),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow

        super.init(window: panel)

        panel.delegate = self
        panel.contentView = NSHostingView(
            rootView: QuickCapturePanel(
                modelContext: modelContext,
                presentationState: presentationState,
                onDismiss: { [weak self] in
                    self?.hide()
                }
            )
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) kullanılmıyor")
    }

    func toggle() {
        guard let panel = window else { return }
        panel.isVisible ? hide() : show()
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
        presentationState.focusRequest += 1
    }

    private func hide() {
        guard let panel = window, panel.isVisible else { return }
        panel.orderOut(nil)
    }

    func windowDidResignKey(_ notification: Notification) {
        guard let panel = notification.object as? NSPanel, panel.isVisible else { return }
        panel.orderOut(nil)
    }
}
