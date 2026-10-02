import Foundation

/// Bitmask değerleri — `Routine.selectedWeekdaysMask` içinde birleştirilir.
enum Weekday: Int, Codable, CaseIterable {
    case monday = 1
    case tuesday = 2
    case wednesday = 4
    case thursday = 8
    case friday = 16
    case saturday = 32
    case sunday = 64
}
