import Foundation

/// Madde 20/21: bir rutinin belirli bir günde aktif olup olmadığını saf şekilde hesaplar.
/// Her gün için Task kopyası oluşturulmaz — Routine kendi entity'si olarak kalır, tamamlanma
/// durumu `RoutineCompletion(routine, date)` kaydının var olup olmamasıyla belirlenir.
struct RoutineScheduler {
    func isActive(_ routine: Routine, on date: Date, calendar: Calendar = .current) -> Bool {
        guard routine.isActive else { return false }

        let weekday = Weekday.from(date: date, calendar: calendar)
        switch routine.recurrenceType {
        case .everyDay:
            return true
        case .weekdays:
            return weekday != .saturday && weekday != .sunday
        case .selectedWeekdays, .weekly:
            return routine.selectedWeekdaysMask & weekday.rawValue != 0
        case .custom:
            // MVP basitleştirmesi: karmaşık interval kuralları (örn. "3 günde bir") ileride eklenebilir.
            return true
        }
    }

    func activeRoutines(from routines: [Routine], on date: Date, calendar: Calendar = .current) -> [Routine] {
        routines.filter { isActive($0, on: date, calendar: calendar) }
    }
}
