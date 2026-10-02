import Foundation
import SwiftData

@Model
final class RoutineCompletion {
    var id: UUID
    var routine: Routine?
    var date: Date
    var completedAt: Date
    var actualDuration: TimeInterval?

    init(routine: Routine, date: Date) {
        self.id = UUID()
        self.routine = routine
        self.date = date
        self.completedAt = .now
        self.actualDuration = nil
    }
}
