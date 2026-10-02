import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var task: TaskItem?
    var state: FocusSessionState

    /// Kalan süre her zaman bu alandan türetilir; saniye sayacı tutulmaz.
    var startDate: Date?
    var plannedDuration: TimeInterval
    var accumulatedPauseDuration: TimeInterval
    var pausedAt: Date?

    var extensionCount: Int
    var endedAt: Date?
    var createdAt: Date

    init(task: TaskItem, plannedDuration: TimeInterval) {
        self.id = UUID()
        self.task = task
        self.state = .idle
        self.startDate = nil
        self.plannedDuration = plannedDuration
        self.accumulatedPauseDuration = 0
        self.pausedAt = nil
        self.extensionCount = 0
        self.endedAt = nil
        self.createdAt = .now
    }
}
