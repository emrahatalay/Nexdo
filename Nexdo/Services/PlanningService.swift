import Foundation

enum PlanningValidationIssue: Equatable {
    case noTasksSelected
    case missingDuration(taskID: UUID, title: String)
    case scheduleConflict(firstTitle: String, secondTitle: String)
    case overCapacity(remainingMinutes: Int)

    /// Kapasite aşımı engelleyici değildir (Madde 9) — kullanıcı onaylayarak geçebilir.
    /// Diğer tüm sorunlar plan kilitlenmeden önce çözülmelidir (Madde 37).
    var isBlocking: Bool {
        if case .overCapacity = self { return false }
        return true
    }

    var message: String {
        switch self {
        case .noTasksSelected:
            "Yarın için henüz hiç iş seçmedin."
        case .missingDuration(_, let title):
            "\"\(title)\" için süre belirlenmedi."
        case .scheduleConflict(let first, let second):
            "\"\(first)\" ve \"\(second)\" çakışıyor."
        case .overCapacity(let remainingMinutes):
            "Kapasite \(-remainingMinutes) dakika aşıldı."
        }
    }
}

/// Madde 37'deki plan kilitleme ön-kontrolleri ve Madde 8/11'deki ardışık zamanlama.
struct PlanningService {
    func validate(tasks: [TaskItem], capacity: CapacityResult) -> [PlanningValidationIssue] {
        var issues: [PlanningValidationIssue] = []

        if tasks.isEmpty {
            issues.append(.noTasksSelected)
        }

        for task in tasks where task.estimatedDuration == nil {
            issues.append(.missingDuration(taskID: task.id, title: task.title))
        }

        let scheduled = tasks
            .compactMap { task -> (TaskItem, Date, Date)? in
                guard let start = task.scheduledStart, let end = task.scheduledEnd else { return nil }
                return (task, start, end)
            }
            .sorted { $0.1 < $1.1 }

        if scheduled.count > 1 {
            for index in 0..<(scheduled.count - 1) {
                let current = scheduled[index]
                let next = scheduled[index + 1]
                if current.2 > next.1 {
                    issues.append(.scheduleConflict(firstTitle: current.0.title, secondTitle: next.0.title))
                }
            }
        }

        if capacity.overCapacity {
            issues.append(.overCapacity(remainingMinutes: capacity.remainingMinutes))
        }

        return issues
    }

    /// `sortOrder`a göre art arda, boşluksuz zaman kutuları üretir. Buffer bu hesaba dahil değildir;
    /// timeline'da ayrı bir blok olarak gösterilir.
    func scheduleSequentially(
        tasks: [TaskItem],
        dayStart: Date
    ) -> [(task: TaskItem, start: Date, end: Date)] {
        var cursor = dayStart
        var result: [(task: TaskItem, start: Date, end: Date)] = []
        for task in tasks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let duration = task.estimatedDuration ?? 0
            let end = cursor.addingTimeInterval(duration)
            result.append((task, cursor, end))
            cursor = end
        }
        return result
    }
}
