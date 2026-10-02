import AppKit
import SwiftUI

/// Madde 5: "Shortcut kullanıcı tarafından Settings içinden değiştirilebilir olmalıdır."
struct ShortcutRecorderView: View {
    @State private var isRecording = false
    @State private var displayString = GlobalShortcutCenter.shared.displayString
    @State private var localMonitor: Any?

    var body: some View {
        HStack {
            Text("Hızlı Yakalama Kısayolu")
            Spacer()
            Button(isRecording ? "Bir tuş kombinasyonu bas…" : displayString) {
                startRecording()
            }
            .buttonStyle(.bordered)
            .disabled(isRecording)
        }
        .onDisappear {
            cancelRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let eventModifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard !eventModifiers.isEmpty else { return nil }

            let newDisplayString = Self.displayString(keyCode: event.keyCode, modifiers: eventModifiers, event: event)
            GlobalShortcutCenter.shared.updateShortcut(
                keyCode: event.keyCode,
                modifiers: eventModifiers,
                displayString: newDisplayString
            )
            displayString = newDisplayString
            cancelRecording()
            return nil
        }
    }

    private func cancelRecording() {
        isRecording = false
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        localMonitor = nil
    }

    private static func displayString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, event: NSEvent) -> String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }

        let rawKey = event.charactersIgnoringModifiers?.uppercased() ?? "?"
        parts.append(rawKey == " " ? "Space" : rawKey)
        return parts.joined()
    }
}
