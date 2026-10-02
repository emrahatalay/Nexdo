import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController {
        PersistenceController(inMemory: true)
    }

    let container: ModelContainer

    private init(inMemory: Bool = false) {
        let schema = Schema([
            TaskItem.self,
            Project.self,
            Routine.self,
            RoutineCompletion.self,
            DailyPlan.self,
            FocusSession.self,
            Postponement.self
        ])

        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)

        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("ModelContainer oluşturulamadı: \(error)")
        }
    }
}
