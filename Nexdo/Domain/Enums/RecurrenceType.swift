import Foundation

enum RecurrenceType: String, Codable, CaseIterable {
    case everyDay
    case weekdays
    case selectedWeekdays
    case weekly
    case custom
}
