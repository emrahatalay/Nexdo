import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var isActive: Bool
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.project)
    var tasks: [TaskItem] = []

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.isActive = true
        self.createdAt = .now
    }
}
