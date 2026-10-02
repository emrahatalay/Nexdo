import SwiftUI

struct RoutineFormSheet: View {
    let onCreate: (String, Int, RoutineTimeOfDay, RecurrenceType, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var minutes = 20
    @State private var timeOfDay: RoutineTimeOfDay = .anytime
    @State private var recurrenceType: RecurrenceType = .everyDay
    @State private var selectedWeekdays: Set<Weekday> = []

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("Yeni Rutin")
                .font(AppTypography.title)

            TextField("Rutin adı", text: $title)
                .textFieldStyle(.roundedBorder)

            Stepper("\(minutes) dk", value: $minutes, in: 5...180, step: 5)

            Picker("Ne zaman", selection: $timeOfDay) {
                ForEach(RoutineTimeOfDay.allCases, id: \.self) { option in
                    Text(label(for: option)).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Picker("Tekrar", selection: $recurrenceType) {
                ForEach(RecurrenceType.allCases, id: \.self) { option in
                    Text(label(for: option)).tag(option)
                }
            }

            if recurrenceType == .selectedWeekdays || recurrenceType == .weekly {
                WeekdaySelector(
                    selection: $selectedWeekdays,
                    allowsMultipleSelection: recurrenceType == .selectedWeekdays
                )
            }

            HStack {
                Spacer()
                Button("Vazgeç") { dismiss() }
                Button("Ekle") {
                    let mask = selectedWeekdays.reduce(0) { $0 | $1.rawValue }
                    onCreate(title, minutes, timeOfDay, recurrenceType, mask)
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(AppSpacing.large)
        .frame(width: 420)
    }

    private func label(for option: RoutineTimeOfDay) -> String {
        switch option {
        case .morning: "Sabah"
        case .afternoon: "Öğleden Sonra"
        case .evening: "Akşam"
        case .anytime: "Herhangi"
        }
    }

    private func label(for option: RecurrenceType) -> String {
        switch option {
        case .everyDay: "Her gün"
        case .weekdays: "Hafta içi"
        case .selectedWeekdays: "Seçili günler"
        case .weekly: "Haftalık (tek gün)"
        case .custom: "Özel"
        }
    }
}
