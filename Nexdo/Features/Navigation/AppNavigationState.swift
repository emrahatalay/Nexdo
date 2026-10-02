import Observation

/// Sidebar seçimini AppEnvironment üzerinden paylaşır ki Today/Focus gibi ekranlar
/// kullanıcıyı başka bir sekmeye yönlendirebilsin (örn. "Bugünü Planla", odak bitince geri dönüş).
@MainActor
@Observable
final class AppNavigationState {
    var selection: SidebarSection? = .today
}
