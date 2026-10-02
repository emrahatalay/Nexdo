import Foundation
import SwiftData

@Model
final class Postponement {
    var id: UUID
    var task: TaskItem?
    var timestamp: Date
    var reason: PostponeReason
    var note: String?

    init(task: TaskItem, reason: PostponeReason, note: String? = nil) {
        self.id = UUID()
        self.task = task
        self.timestamp = .now
        self.reason = reason
        self.note = note
    }
}
