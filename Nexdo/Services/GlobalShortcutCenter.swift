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

    /// Varsayılan Quick Capture kısayolu: ⌘⇧Space. Settings'ten değiştirilebilir
    /// hale getirilmesi Phase 8 (Settings/Shortcuts) kapsamındadır.
    private let keyCode: UInt16 = 49
    private let requiredModifiers: NSEvent.ModifierFlags = [.command, .shift]

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var onTrigger: (() -> Void)?

    private init() {}

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
            && event.modifierFlags.intersection(.deviceIndependentFlagsMask) == requiredModifiers
    }
}
