import Foundation

enum TaskSource: String, Codable, CaseIterable {
    case manual
    case quickCapture
    case recurring
    case imported
}
