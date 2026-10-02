import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HistoryViewModel {
    struct SessionRecord: Identifiable, Equatable {
        let id: UUID
        let taskID: UUID?
        let taskTitle: String
        let estimatedMinutes: Int
        let actualMinutes: Int
        let state: FocusSessionState
        let canRestore: Bool
    }

    struct DaySummary: Identifiable, Equatable {
        let date: Date
        let completedSessions: [SessionRecord]
        let stoppedSessions: [SessionRecord]
        let postponementCount: Int
        let totalActualMinutes: Int
        let routineExpected: Int
        let routineCompleted: Int
        var id: Date { date }
    }

    private let modelContext: ModelContext
    private let statisticsService = StatisticsService()
    private let scheduler = RoutineScheduler()

    private(set) var estimationInsight = EstimationInsight(sampleSize: 0, averageRatio: 0)
    private(set) var days: [DaySummary] = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    func refresh() {
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        estimationInsight = statisticsService.estimationInsight(for: allTasks)

        let allSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let finishedSessions = allSessions.filter { $0.state == .completed || $0.state == .stopped }

        let allPostponements = (try? modelContext.fetch(FetchDescriptor<Postponement>())) ?? []
        let allRoutines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        let allCompletions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []

        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: finishedSessions) { session in
            calendar.startOfDay(for: session.endedAt ?? session.createdAt)
        }

        let sortedDates = groupedByDay.keys.sorted(by: >).prefix(14)

        days = sortedDates.map { date in
            let sessions = groupedByDay[date] ?? []
            let completed = sessions.filter { $0.state == .completed }
            let stopped = sessions.filter { $0.state == .stopped }
            let postponements = allPostponements.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            let routinesExpected = scheduler.activeRoutines(from: allRoutines, on: date)
            let routinesCompleted = allCompletions.filter { calendar.isDate($0.date, inSameDayAs: date) }

            return DaySummary(
                date: date,
                completedSessions: completed.map(Self.record),
                stoppedSessions: stopped.map(Self.record),
                postponementCount: postponements.count,
                totalActualMinutes: sessions.reduce(0) { $0 + Int($1.elapsedTime(at: $1.endedAt ?? .now) / 60) },
                routineExpected: routinesExpected.count,
                routineCompleted: routinesCompleted.count
            )
        }
    }

    func restoreToInbox(_ record: SessionRecord) {
        guard record.canRestore, let taskID = record.taskID else { return }
        let tasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        guard let task = tasks.first(where: { $0.id == taskID }) else { return }

        task.status = .inbox
        task.eisenhowerQuadrant = .unset
        task.plannedDate = nil
        task.scheduledStart = nil
        task.scheduledEnd = nil
        task.startedAt = nil
        task.completedAt = nil
        task.sortOrder = 0
        task.updatedAt = .now

        do {
            try modelContext.save()
            refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private static func record(_ session: FocusSession) -> SessionRecord {
        SessionRecord(
            id: session.id,
            taskID: session.task?.id,
            taskTitle: session.task?.title ?? "Silinmiş görev",
            estimatedMinutes: Int(session.plannedDuration / 60),
            actualMinutes: Int(session.elapsedTime(at: session.endedAt ?? .now) / 60),
            state: session.state,
            canRestore: session.task.map {
                $0.status == .completed || $0.status == .stopped || $0.status == .cancelled
            } ?? false
        )
    }
}
