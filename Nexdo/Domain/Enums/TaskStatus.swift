import Foundation

enum TaskStatus: String, Codable, CaseIterable {
    case inbox
    case planned
    case active
    case completed
    case stopped
    case cancelled
}
