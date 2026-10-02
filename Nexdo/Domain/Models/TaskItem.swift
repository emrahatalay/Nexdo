import Foundation
import SwiftData

@Model
final class TaskItem {
    var id: UUID
    var title: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    var status: TaskStatus
    var eisenhowerQuadrant: EisenhowerQuadrant

    var estimatedDuration: TimeInterval?
    var actualDuration: TimeInterval

    var plannedDate: Date?
    var scheduledStart: Date?
    var scheduledEnd: Date?

    var sortOrder: Int

    var firstAction: String?

    var startedAt: Date?
    var completedAt: Date?

    var extensionCount: Int
    var postponeCount: Int
    var postponeReason: PostponeReason?

    var source: TaskSource

    var project: Project?

    @Relationship(deleteRule: .cascade, inverse: \FocusSession.task)
    var focusSessions: [FocusSession] = []

    @Relationship(deleteRule: .cascade, inverse: \Postponement.task)
    var postponements: [Postponement] = []

    init(title: String, source: TaskSource = .manual) {
        self.id = UUID()
        self.title = title
        self.notes = nil
        self.createdAt = .now
        self.updatedAt = .now
        self.status = .inbox
        self.eisenhowerQuadrant = .unset
        self.estimatedDuration = nil
        self.actualDuration = 0
        self.plannedDate = nil
        self.scheduledStart = nil
        self.scheduledEnd = nil
        self.sortOrder = 0
        self.firstAction = nil
        self.startedAt = nil
        self.completedAt = nil
        self.extensionCount = 0
        self.postponeCount = 0
        self.postponeReason = nil
        self.source = source
    }
}
