import Foundation
import Testing
@testable import Nexdo

struct TodayPlanEditingServiceTests {
    private let service = TodayPlanEditingService()
    private let today = Date(timeIntervalSince1970: 1_800_000_000)
    private let now = Date(timeIntervalSince1970: 1_800_036_000)

    @Test func addMovesInboxTaskIntoTodaysPlan() {
        let task = TaskItem(title: "Bugün eklenecek iş")

        let didAdd = service.add(
            task,
            to: today,
            existingTasks: [],
            now: now,
            defaultMinutes: 25
        )

        #expect(didAdd)
        #expect(task.status == .planned)
        #expect(task.plannedDate == today)
        #expect(task.estimatedDuration == TimeInterval(25 * 60))
        #expect(task.scheduledStart == now)
        #expect(task.scheduledEnd == now.addingTimeInterval(25 * 60))
        #expect(task.sortOrder == 0)
    }

    @Test func addAppendsAfterExistingScheduledTasks() {
        let existing = TaskItem(title: "Mevcut iş")
        existing.sortOrder = 4
        existing.scheduledEnd = now.addingTimeInterval(30 * 60)
        let task = TaskItem(title: "Sonradan eklenen iş")
        task.estimatedDuration = 15 * 60

        service.add(
            task,
            to: today,
            existingTasks: [existing],
            now: now,
            defaultMinutes: 25
        )

        #expect(task.sortOrder == 5)
        #expect(task.scheduledStart == existing.scheduledEnd)
        #expect(task.scheduledEnd == now.addingTimeInterval(45 * 60))
    }

    @Test func removeReturnsPlannedTaskToInbox() {
        let task = TaskItem(title: "Bugünden çıkarılacak iş")
        task.status = .planned
        task.plannedDate = today
        task.scheduledStart = now
        task.scheduledEnd = now.addingTimeInterval(25 * 60)

        let didRemove = service.remove(task, now: now)

        #expect(didRemove)
        #expect(task.status == .inbox)
        #expect(task.plannedDate == nil)
        #expect(task.scheduledStart == nil)
        #expect(task.scheduledEnd == nil)
    }

    @Test func activeTaskCannotBeRemoved() {
        let task = TaskItem(title: "Aktif iş")
        task.status = .active
        task.plannedDate = today

        let didRemove = service.remove(task, now: now)

        #expect(!didRemove)
        #expect(task.status == .active)
        #expect(task.plannedDate == today)
    }
}
