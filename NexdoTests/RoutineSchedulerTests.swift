import Foundation
import Testing
@testable import Nexdo

struct RoutineSchedulerTests {
    private let scheduler = RoutineScheduler()
    private let calendar = Calendar(identifier: .gregorian)

    /// Gerçek takvim tarihlerini ezbere varsaymak yerine, istenen haftanın gününe sahip bir
    /// tarihi 1970-01-01'den başlayıp ileri sararak bulur — test, takvim bilgisine bağımlı değildir.
    private func date(weekday: Weekday) -> Date {
        var cursor = Date(timeIntervalSince1970: 0)
        while Weekday.from(date: cursor, calendar: calendar) != weekday {
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }
        return cursor
    }

    @Test func everyDayIsAlwaysActive() {
        let routine = Routine(title: "Her gün", estimatedDuration: 600, recurrenceType: .everyDay)
        #expect(scheduler.isActive(routine, on: date(weekday: .monday), calendar: calendar))
        #expect(scheduler.isActive(routine, on: date(weekday: .saturday), calendar: calendar))
    }

    @Test func weekdaysExcludesSaturdayAndSunday() {
        let routine = Routine(title: "Hafta içi", estimatedDuration: 600, recurrenceType: .weekdays)
        #expect(scheduler.isActive(routine, on: date(weekday: .monday), calendar: calendar))
        #expect(scheduler.isActive(routine, on: date(weekday: .friday), calendar: calendar))
        #expect(!scheduler.isActive(routine, on: date(weekday: .saturday), calendar: calendar))
        #expect(!scheduler.isActive(routine, on: date(weekday: .sunday), calendar: calendar))
    }

    @Test func selectedWeekdaysOnlyMatchesMask() {
        let routine = Routine(title: "Seçili günler", estimatedDuration: 600, recurrenceType: .selectedWeekdays)
        routine.selectedWeekdaysMask = Weekday.monday.rawValue | Weekday.wednesday.rawValue

        #expect(scheduler.isActive(routine, on: date(weekday: .monday), calendar: calendar))
        #expect(scheduler.isActive(routine, on: date(weekday: .wednesday), calendar: calendar))
        #expect(!scheduler.isActive(routine, on: date(weekday: .tuesday), calendar: calendar))
    }

    @Test func weeklyMatchesSingleSelectedDay() {
        let routine = Routine(title: "Haftalık", estimatedDuration: 600, recurrenceType: .weekly)
        routine.selectedWeekdaysMask = Weekday.sunday.rawValue

        #expect(scheduler.isActive(routine, on: date(weekday: .sunday), calendar: calendar))
        #expect(!scheduler.isActive(routine, on: date(weekday: .monday), calendar: calendar))
    }

    @Test func inactiveRoutineIsNeverActiveRegardlessOfRecurrence() {
        let routine = Routine(title: "Pasif", estimatedDuration: 600, recurrenceType: .everyDay)
        routine.isActive = false
        #expect(!scheduler.isActive(routine, on: date(weekday: .monday), calendar: calendar))
    }

    @Test func activeRoutinesFiltersCorrectSubset() {
        let daily = Routine(title: "Günlük", estimatedDuration: 300, recurrenceType: .everyDay)
        let weekdaysOnly = Routine(title: "Hafta içi", estimatedDuration: 300, recurrenceType: .weekdays)
        let sunday = date(weekday: .sunday)

        let active = scheduler.activeRoutines(from: [daily, weekdaysOnly], on: sunday, calendar: calendar)

        #expect(active.map(\.title) == ["Günlük"])
    }
}
