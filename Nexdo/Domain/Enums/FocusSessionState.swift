import Foundation

enum FocusSessionState: String, Codable, CaseIterable {
    case idle
    case running
    case paused
    case expired
    case completed
    case stopped
}
