import Foundation
import SwiftData

/// Kompozisyon kökü: paylaşılan `ModelContainer` ve ileride eklenecek servisler buradan dağıtılır.
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let modelContainer: ModelContainer

    private init() {
        self.modelContainer = PersistenceController.shared.container
    }
}
