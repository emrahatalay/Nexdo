import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class TodayViewModel {
    private let modelContext: ModelContext
    private let today: Date

    private(set) var todayTasks: [TaskItem] = []
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
    }

    /// Postpone edilen görev bugünün sırasının sonuna atılır ki ŞİMDİ aynı işte sıkışıp kalmasın.
    func recordPostponement(for task: TaskItem, reason: PostponeReason) {
        task.sortOrder = (todayTasks.map(\.sortOrder).max() ?? task.sortOrder) + 1
        PostponementRecorder().record(task: task, reason: reason, in: modelContext)
        refresh()
    }
}
