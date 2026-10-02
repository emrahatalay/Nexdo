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

    static func from(date: Date, calendar: Calendar = .current) -> Weekday {
        // Calendar.component(.weekday): 1 = Pazar ... 7 = Cumartesi (takvimden bağımsız).
        switch calendar.component(.weekday, from: date) {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
}
