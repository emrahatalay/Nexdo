import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class RoutinesViewModel {
    private let modelContext: ModelContext
    private let scheduler = RoutineScheduler()
    private let today = Calendar.current.startOfDay(for: .now)

    private(set) var allRoutines: [Routine] = []
    private(set) var todaysRoutines: [Routine] = []
    private(set) var completedRoutineIDs: Set<UUID> = []
    var errorMessage: String?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    func isCompletedToday(_ routine: Routine) -> Bool {
        completedRoutineIDs.contains(routine.id)
    }

    func refresh() {
        allRoutines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        todaysRoutines = scheduler.activeRoutines(from: allRoutines, on: today)

        let completions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
        completedRoutineIDs = Set(
            completions
                .filter { $0.date == today }
                .compactMap { $0.routine?.id }
        )
    }

    /// Her gün için Task kopyası oluşturulmaz (Madde 20) — tamamlanma durumu bu gün için
    /// bir `RoutineCompletion` kaydının var olup olmamasıyla temsil edilir.
    func toggleCompletion(for routine: Routine) {
        if isCompletedToday(routine) {
            let completions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
            for completion in completions where completion.routine?.id == routine.id && completion.date == today {
                modelContext.delete(completion)
            }
        } else {
            modelContext.insert(RoutineCompletion(routine: routine, date: today))
        }
        save()
    }

    func createRoutine(
        title: String,
        estimatedMinutes: Int,
        timeOfDay: RoutineTimeOfDay,
        recurrenceType: RecurrenceType,
        selectedWeekdaysMask: Int
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let routine = Routine(
            title: trimmed,
            estimatedDuration: TimeInterval(estimatedMinutes * 60),
            timeOfDay: timeOfDay,
            recurrenceType: recurrenceType
        )
        routine.selectedWeekdaysMask = selectedWeekdaysMask
        modelContext.insert(routine)
        save()
    }

    func setActive(_ routine: Routine, isActive: Bool) {
        routine.isActive = isActive
        save()
    }

    func delete(_ routine: Routine) {
        modelContext.delete(routine)
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }
}
