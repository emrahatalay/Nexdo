import Foundation

struct TodayPlanEditingService {
    @discardableResult
    func add(
        _ task: TaskItem,
        to date: Date,
        existingTasks: [TaskItem],
        now: Date = .now,
        defaultMinutes: Int
    ) -> Bool {
        guard task.status == .inbox || task.status == .stopped else { return false }

        let duration = task.estimatedDuration ?? TimeInterval(max(defaultMinutes, 5) * 60)
        let latestScheduledEnd = existingTasks.compactMap(\.scheduledEnd).max() ?? now
        let start = max(latestScheduledEnd, now)

        task.status = .planned
        task.plannedDate = date
        task.estimatedDuration = duration
        task.sortOrder = (existingTasks.map(\.sortOrder).max() ?? -1) + 1
        task.scheduledStart = start
        task.scheduledEnd = start.addingTimeInterval(duration)
        task.updatedAt = now
        return true
    }

    @discardableResult
    func remove(_ task: TaskItem, now: Date = .now) -> Bool {
        guard task.status != .active else { return false }

        task.status = .inbox
        task.plannedDate = nil
        task.scheduledStart = nil
        task.scheduledEnd = nil
        task.sortOrder = 0
        task.updatedAt = now
        return true
    }
}
