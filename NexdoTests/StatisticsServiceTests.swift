import Foundation
import Testing
@testable import Nexdo

struct StatisticsServiceTests {
    private let service = StatisticsService()

    private func completedTask(estimatedMinutes: Int, actualMinutes: Int, completedAt: Date) -> TaskItem {
        let task = TaskItem(title: "Görev")
        task.status = .completed
        task.estimatedDuration = TimeInterval(estimatedMinutes * 60)
        task.actualDuration = TimeInterval(actualMinutes * 60)
        task.completedAt = completedAt
        return task
    }

    @Test func estimationInsightAveragesRatioAcrossCompletedTasks() {
        let now = Date()
        let tasks = [
            completedTask(estimatedMinutes: 30, actualMinutes: 30, completedAt: now),
            completedTask(estimatedMinutes: 20, actualMinutes: 40, completedAt: now.addingTimeInterval(-60))
        ]
        // Oranlar: 1.0 ve 2.0 -> ortalama 1.5 (%150)
        let insight = service.estimationInsight(for: tasks)
        #expect(insight.sampleSize == 2)
        #expect(abs(insight.averageRatio - 1.5) < 0.0001)
        #expect(insight.summary == "Son 2 görevde planladığın sürenin ortalama %150'ini kullandın.")
    }

    @Test func estimationInsightIgnoresTasksWithoutEstimateOrActual() {
        let task = TaskItem(title: "Tahminsiz")
        task.status = .completed
        task.actualDuration = 600
        // estimatedDuration nil bırakıldı.

        let insight = service.estimationInsight(for: [task])
        #expect(insight.sampleSize == 0)
        #expect(insight.summary == nil)
    }

    @Test func estimationInsightRespectsRecentLimit() {
        let now = Date()
        let tasks = (0..<5).map { index in
            completedTask(estimatedMinutes: 10, actualMinutes: 10, completedAt: now.addingTimeInterval(-Double(index) * 60))
        }
        let insight = service.estimationInsight(for: tasks, recentLimit: 3)
        #expect(insight.sampleSize == 3)
    }

    @Test func dayStatisticsAggregatesCompletedAndStoppedSessions() {
        let day = Calendar.current.startOfDay(for: Date())

        let completedTask = TaskItem(title: "Tamamlanan")
        let completedSession = FocusSession(task: completedTask, plannedDuration: 30 * 60)
        completedSession.state = .completed
        completedSession.startDate = day
        completedSession.endedAt = day.addingTimeInterval(35 * 60)

        let stoppedTask = TaskItem(title: "Durdurulan")
        let stoppedSession = FocusSession(task: stoppedTask, plannedDuration: 45 * 60)
        stoppedSession.state = .stopped
        stoppedSession.startDate = day
        stoppedSession.endedAt = day.addingTimeInterval(20 * 60)

        let stats = service.dayStatistics(
            for: day,
            allTasks: [completedTask, stoppedTask],
            allSessions: [completedSession, stoppedSession],
            allRoutines: [],
            allCompletions: [],
            scheduler: RoutineScheduler()
        )

        #expect(stats.completedCount == 1)
        #expect(stats.stoppedCount == 1)
        #expect(stats.totalPlannedTasks == 2)
        #expect(stats.plannedMinutes == 75)
        #expect(stats.actualMinutes == 55)
    }

    @Test func dayStatisticsCountsExpectedAndCompletedRoutines() {
        let day = Calendar.current.startOfDay(for: Date())
        let routine = Routine(title: "Yürüyüş", estimatedDuration: 600, recurrenceType: .everyDay)
        let completion = RoutineCompletion(routine: routine, date: day)

        let stats = service.dayStatistics(
            for: day,
            allTasks: [],
            allSessions: [],
            allRoutines: [routine],
            allCompletions: [completion],
            scheduler: RoutineScheduler()
        )

        #expect(stats.routineExpectedCount == 1)
        #expect(stats.routineCompletedCount == 1)
    }
}
