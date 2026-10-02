import SwiftUI

/// `selectedWeekdays` (çoklu seçim) ve `weekly` (tek seçim) recurrence tipleri için ortak kontrol.
struct WeekdaySelector: View {
    @Binding var selection: Set<Weekday>
    let allowsMultipleSelection: Bool

    private let order: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            ForEach(order, id: \.self) { day in
                Button(shortLabel(day)) {
                    toggle(day)
                }
                .buttonStyle(.bordered)
                .tint(selection.contains(day) ? .accentColor : nil)
            }
        }
    }

    private func toggle(_ day: Weekday) {
        if allowsMultipleSelection {
            if selection.contains(day) {
                selection.remove(day)
            } else {
                selection.insert(day)
            }
        } else {
            selection = [day]
        }
    }

    private func shortLabel(_ day: Weekday) -> String {
        switch day {
        case .monday: "Pt"
        case .tuesday: "Sa"
        case .wednesday: "Ça"
        case .thursday: "Pe"
        case .friday: "Cu"
        case .saturday: "Ct"
        case .sunday: "Pz"
        }
    }
}
