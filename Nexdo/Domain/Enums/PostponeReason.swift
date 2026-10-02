import Foundation

enum PostponeReason: String, Codable, CaseIterable {
    case noEnergy
    case taskTooBig
    case unclearNextStep
    case somethingElseCameUp
    case environmentNotSuitable
    case other
}
