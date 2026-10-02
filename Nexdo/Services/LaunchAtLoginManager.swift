import ServiceManagement

/// Madde 28: "Launch at login". Modern `SMAppService` API'si — yardımcı bir
/// login item hedefi gerekmeden doğrudan ana uygulamayı kaydeder.
enum LaunchAtLoginManager {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Kullanıcıya bildirmeye değer bir arıza değil: Settings ekranı toggle'ı
            // mevcut gerçek duruma göre her açılışta yeniden okuyup senkronize eder.
        }
    }
}
