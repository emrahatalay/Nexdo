import Foundation
import Testing
@testable import Nexdo

struct PlanningServiceTests {
    private let service = PlanningService()
    private let capacityService = CapacityService()

    @Test func noTasksSelectedIsBlocking() {
        let capacity = capacityService.evaluate(availableMinutes: 360, routineMinutes: 0, plannedTaskMinutes: 0, bufferMinutes: 45)
        let issues = service.validate(tasks: [], capacity: capacity)
        #expect(issues.contains(.noTasksSelected))
    }

    @Test func missingDurationIsReportedAndBlocking() {
        let task = TaskItem(title: "Süresiz iş")
        let capacity = capacityService.evaluate(availableMinutes: 360, routineMinutes: 0, plannedTaskMinutes: 0, bufferMinutes: 45)
        let issues = service.validate(tasks: [task], capacity: capacity)

        let issue = issues.first { if case .missingDuration = $0 { true } else { false } }
        #expect(issue != nil)
        #expect(issue?.isBlocking == true)
    }

    @Test func overCapacityIsReportedButNotBlocking() {
        let task = TaskItem(title: "Uzun iş")
        task.estimatedDuration = 330 * 60
        let capacity = capacityService.evaluate(availableMinutes: 360, routineMinutes: 0, plannedTaskMinutes: 330, bufferMinutes: 45)
        let issues = service.validate(tasks: [task], capacity: capacity)

        let issue = issues.first { if case .overCapacity = $0 { true } else { false } }
        #expect(issue != nil)
        #expect(issue?.isBlocking == false)
    }

    @Test func scheduleSequentiallyChainsTasksBackToBackInSortOrder() {
        let first = TaskItem(title: "A")
        first.estimatedDuration = 30 * 60
        first.sortOrder = 0
        let second = TaskItem(title: "B")
        second.estimatedDuration = 45 * 60
        second.sortOrder = 1

        let dayStart = Date(timeIntervalSince1970: 0)
        // Kasıtlı olarak ters sırada veriliyor — fonksiyon sortOrder'a göre sıralamalı.
        let scheduled = service.scheduleSequentially(tasks: [second, first], dayStart: dayStart)

        #expect(scheduled[0].task.title == "A")
        #expect(scheduled[0].start == dayStart)
        #expect(scheduled[1].start == dayStart.addingTimeInterval(30 * 60))
        #expect(scheduled[1].end == dayStart.addingTimeInterval(75 * 60))
    }

    @Test func detectsScheduleConflictBetweenOverlappingTasks() {
        let dayStart = Date(timeIntervalSince1970: 0)
        let first = TaskItem(title: "A")
        first.estimatedDuration = 60 * 60
        first.scheduledStart = dayStart
        first.scheduledEnd = dayStart.addingTimeInterval(60 * 60)

        let second = TaskItem(title: "B")
        second.estimatedDuration = 30 * 60
        second.scheduledStart = dayStart.addingTimeInterval(30 * 60)
        second.scheduledEnd = dayStart.addingTimeInterval(90 * 60)

        let capacity = capacityService.evaluate(availableMinutes: 360, routineMinutes: 0, plannedTaskMinutes: 90, bufferMinutes: 45)
        let issues = service.validate(tasks: [first, second], capacity: capacity)

        #expect(issues.contains { if case .scheduleConflict = $0 { true } else { false } })
    }
}
