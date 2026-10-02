import Foundation
import SwiftData

@Model
final class DailyPlan {
    @Attribute(.unique) var date: Date
    var availableFocusMinutes: Int
    var plannedTaskMinutes: Int
    var routineMinutes: Int
    var breakMinutes: Int
    var bufferMinutes: Int
    var isLocked: Bool
    var lockedAt: Date?

    init(date: Date, availableFocusMinutes: Int) {
        self.date = date
        self.availableFocusMinutes = availableFocusMinutes
        self.plannedTaskMinutes = 0
        self.routineMinutes = 0
        self.breakMinutes = 0
        self.bufferMinutes = 0
        self.isLocked = false
        self.lockedAt = nil
    }
}
