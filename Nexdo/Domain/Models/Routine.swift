import Foundation
import SwiftData

@Model
final class Routine {
    var id: UUID
    var title: String
    var estimatedDuration: TimeInterval
    var timeOfDay: RoutineTimeOfDay
    var preferredStartTime: Date?

    /// `RecurrenceType.selectedWeekdays`/`.weekly` için `Weekday` bitmask'i.
    var recurrenceType: RecurrenceType
    var selectedWeekdaysMask: Int

    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineCompletion.routine)
    var completions: [RoutineCompletion] = []

    init(
        title: String,
        estimatedDuration: TimeInterval,
        timeOfDay: RoutineTimeOfDay = .anytime,
        recurrenceType: RecurrenceType = .everyDay
    ) {
        self.id = UUID()
        self.title = title
        self.estimatedDuration = estimatedDuration
        self.timeOfDay = timeOfDay
        self.preferredStartTime = nil
        self.recurrenceType = recurrenceType
        self.selectedWeekdaysMask = 0
        self.isActive = true
        self.createdAt = .now
    }
}
