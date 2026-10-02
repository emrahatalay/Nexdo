import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    private let modelContext: ModelContext
    private let editingService = TodayPlanEditingService()
    private let routineScheduler = RoutineScheduler()
    private let today: Date

    private(set) var todayTasks: [TaskItem] = []
    private(set) var availableTasks: [TaskItem] = []
    private(set) var todayRoutines: [Routine] = []
    private(set) var completedRoutineIDs: Set<UUID> = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.today = Calendar.current.startOfDay(for: .now)
        refresh()
    }

    /// Aktif oturumu olan görev varsa ŞİMDİ odur; yoksa sıradaki planlanmış görev.
    var currentTask: TaskItem? {
        todayTasks.first { $0.status == .active } ?? todayTasks.first { $0.status == .planned }
    }

    var nextTask: TaskItem? {
        guard let current = currentTask else { return nil }
        return todayTasks.first { $0.id != current.id && $0.sortOrder > current.sortOrder }
    }

    func refresh() {
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []

        todayTasks = allTasks
            .filter { $0.plannedDate == today && ($0.status == .planned || $0.status == .active) }
            .sorted { $0.sortOrder < $1.sortOrder }

        availableTasks = allTasks
            .filter { $0.status == .inbox || $0.status == .stopped }
            .sorted { $0.createdAt > $1.createdAt }

        let allRoutines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        todayRoutines = routineScheduler
            .activeRoutines(from: allRoutines, on: today)
            .sorted { routineSortKey($0) < routineSortKey($1) }

        let completions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
        completedRoutineIDs = Set(
            completions
                .filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
                .compactMap { $0.routine?.id }
        )
    }

    func isRoutineCompleted(_ routine: Routine) -> Bool {
        completedRoutineIDs.contains(routine.id)
    }

    func toggleRoutineCompletion(_ routine: Routine) {
        if isRoutineCompleted(routine) {
            let completions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
            for completion in completions where
                completion.routine?.id == routine.id
                && Calendar.current.isDate(completion.date, inSameDayAs: today) {
                modelContext.delete(completion)
            }
        } else {
            modelContext.insert(RoutineCompletion(routine: routine, date: today))
        }
        save()
    }

    func addToToday(_ task: TaskItem) {
        let defaultMinutes = UserDefaults.standard.integer(
            forKey: AppSettingsKey.defaultTimeboxMinutes
        )
        guard editingService.add(
            task,
            to: today,
            existingTasks: todayTasks,
            defaultMinutes: defaultMinutes
        ) else { return }
        save()
    }

    func removeFromToday(_ task: TaskItem) {
        guard editingService.remove(task) else { return }
        save()
    }

    /// Ertelenen görev bugünün sırasının sonuna atılır ki ŞİMDİ aynı işte sıkışıp kalmasın.
    func recordPostponement(for task: TaskItem, reason: PostponeReason) {
        task.sortOrder = (todayTasks.map(\.sortOrder).max() ?? task.sortOrder) + 1
        PostponementRecorder().record(task: task, reason: reason, in: modelContext)
        refresh()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }

    private func routineSortKey(_ routine: Routine) -> Int {
        switch routine.timeOfDay {
        case .morning: 0
        case .afternoon: 1
        case .evening: 2
        case .anytime: 3
        }
    }
}
