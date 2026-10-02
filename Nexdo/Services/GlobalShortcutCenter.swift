import AppKit
import IOKit.hid

/// Quick Capture panelini sistem genelinde açan kısayolu yönetir.
///
/// Uygulama ön planda değilken klavye olaylarını almak App Sandbox altında
/// "Input Monitoring" TCC izni gerektirir (Accessibility ile karıştırılmamalı —
/// o, başka uygulamaları otomatikleştirmek için gerekir ve burada kullanılmıyor).
/// İzin verilmemişse global monitor hiç tetiklenmez; uygulama en azından kendisi
/// öndeyken (local monitor) çalışmaya devam eder.
@MainActor
final class GlobalShortcutCenter {
    static let shared = GlobalShortcutCenter()

    /// Madde 5: kısayol Settings'ten değiştirilebilir olmalı. Varsayılan: ⌘⇧Space.
    private(set) var keyCode: UInt16
    private(set) var modifiers: NSEvent.ModifierFlags
    private(set) var displayString: String

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onTrigger: (() -> Void)?

    private init() {
        let defaults = UserDefaults.standard
        self.keyCode = UInt16(defaults.integer(forKey: AppSettingsKey.quickCaptureKeyCode))
        self.modifiers = NSEvent.ModifierFlags(
            rawValue: UInt(defaults.integer(forKey: AppSettingsKey.quickCaptureModifiers))
        )
        self.displayString = defaults.string(forKey: AppSettingsKey.quickCaptureDisplayString) ?? "⌘⇧Space"
    }

    func start(onTrigger: @escaping () -> Void) {
        self.onTrigger = onTrigger

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handle(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.matches(event) else { return event }
            self.onTrigger?()
            return nil
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    /// Settings > Kısayollar'daki kaydedici bu metodu çağırır; yakalanan tuş o anda
    /// bir modifier ile basılmış olmalıdır (en az bir modifier zorunlu), aksi halde
    /// kısayol normal yazım sırasında kazara tetiklenebilir.
    func updateShortcut(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, displayString: String) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.displayString = displayString

        let defaults = UserDefaults.standard
        defaults.set(Int(keyCode), forKey: AppSettingsKey.quickCaptureKeyCode)
        defaults.set(Int(modifiers.rawValue), forKey: AppSettingsKey.quickCaptureModifiers)
        defaults.set(displayString, forKey: AppSettingsKey.quickCaptureDisplayString)

        if let onTrigger {
            stop()
            start(onTrigger: onTrigger)
        }
    }

    /// `IOHIDRequestAccess` sistem izin diyaloğu kapanana kadar çağıran thread'i bloke eder.
    /// Ana thread'de çağrılırsa tüm uygulama açılışını donduruyormuş gibi görünür — bu yüzden
    /// `nonisolated` olup işi tamamen arka plan kuyruğuna devrediyor.
    nonisolated func requestInputMonitoringAccessIfNeeded() {
        DispatchQueue.global(qos: .utility).async {
            guard IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeUnknown else { return }
            IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        }
    }

    private func handle(_ event: NSEvent) {
        guard matches(event) else { return }
        onTrigger?()
    }

    private func matches(_ event: NSEvent) -> Bool {
        event.keyCode == keyCode
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == modifiers
    }
}
