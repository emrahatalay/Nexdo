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

    /// Madde 15/39: her zaman duvar saatinden türetilir, asla sayaç azaltılarak değil.
    /// Bu sayede sleep/wake veya app relaunch sonrası otomatik doğru sonuca "self-heal" eder.
    func elapsedTime(at date: Date = .now) -> TimeInterval {
        guard let startDate else { return 0 }
        let activePauseOffset = (state == .paused) ? date.timeIntervalSince(pausedAt ?? date) : 0
        return date.timeIntervalSince(startDate) - accumulatedPauseDuration - activePauseOffset
    }

    func remainingTime(at date: Date = .now) -> TimeInterval {
        plannedDuration - elapsedTime(at: date)
    }
}
