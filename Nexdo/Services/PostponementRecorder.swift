import Foundation
import SwiftData

/// Madde 19: Today (başlamadan önce) ve Focus Mode (oturum sırasında "Şimdi yapamıyorum")
/// aynı yakalama mantığını paylaşır.
struct PostponementRecorder {
    func record(task: TaskItem, reason: PostponeReason, note: String? = nil, in context: ModelContext) {
        let postponement = Postponement(task: task, reason: reason, note: note)
        context.insert(postponement)
        task.postponeCount += 1
        task.postponeReason = reason
        task.updatedAt = .now
        try? context.save()
    }
}
