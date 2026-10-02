import SwiftUI

struct RoutineFormSheet: View {
    let onCreate: (String, Int, RoutineTimeOfDay, RecurrenceType, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var minutes = 20
    @State private var timeOfDay: RoutineTimeOfDay = .anytime
    @State private var recurrenceType: RecurrenceType = .everyDay
    @State private var selectedWeekdays: Set<Weekday> = []
    @FocusState private var isTitleFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            RoutineFormHeader()

            Divider()

            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    RoutineDetailsSection(
                        title: $title,
                        minutes: $minutes,
                        isTitleFocused: $isTitleFocused
                    )

                    RoutineScheduleSection(
                        timeOfDay: $timeOfDay,
                        recurrenceType: $recurrenceType,
                        selectedWeekdays: $selectedWeekdays
                    )
                }
                .padding(AppSpacing.large)
            }

            Divider()

            RoutineFormActions(
                isCreateDisabled: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                onCancel: { dismiss() },
                onCreate: createRoutine
            )
        }
        .frame(minWidth: 440, idealWidth: 500, maxWidth: 560)
        .fixedSize(horizontal: false, vertical: true)
        .background(.background)
        .onAppear {
            isTitleFocused = true
        }
    }

    private func createRoutine() {
        let mask = selectedWeekdays.reduce(0) { $0 | $1.rawValue }
        onCreate(title, minutes, timeOfDay, recurrenceType, mask)
    }
}

private struct RoutineFormHeader: View {
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: "repeat.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .frame(width: 42, height: 42)
                .background(.green.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("Yeni Rutin")
                    .font(AppTypography.title)

                Text("Düzenli yapmak istediğin bir alışkanlık oluştur.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.large)
    }
}

private struct RoutineDetailsSection: View {
    @Binding var title: String
    @Binding var minutes: Int
    let isTitleFocused: FocusState<Bool>.Binding

    var body: some View {
        AppCard(padding: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Rutin bilgileri",
                    subtitle: "Net ve kolay hatırlanan bir ad seç.",
                    systemImage: "text.cursor"
                )

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Rutin adı")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                    TextField("Örn. Günlük yürüyüş", text: $title)
                        .textFieldStyle(.roundedBorder)
                        .controlSize(.large)
                        .focused(isTitleFocused)
                }

                HStack {
                    Label("Tahmini süre", systemImage: "clock")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper(value: $minutes, in: 5...180, step: 5) {
                        Text("\(minutes) dakika")
                            .font(.body.weight(.semibold))
                            .monospacedDigit()
                    }
                    .fixedSize()
                }
            }
        }
    }
}

private struct RoutineScheduleSection: View {
    @Binding var timeOfDay: RoutineTimeOfDay
    @Binding var recurrenceType: RecurrenceType
    @Binding var selectedWeekdays: Set<Weekday>

    var body: some View {
        AppCard(padding: AppSpacing.medium) {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Program",
                    subtitle: "Ritmin günün hangi bölümünde ve ne sıklıkta görünsün?",
                    systemImage: "calendar"
                )

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text("Günün zamanı")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                    Picker("Günün zamanı", selection: $timeOfDay) {
                        ForEach(RoutineTimeOfDay.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                }

                Divider()

                HStack {
                    Label("Tekrar", systemImage: "repeat")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Picker("Tekrar", selection: $recurrenceType) {
                        ForEach(RecurrenceType.allCases, id: \.self) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 230)
                }

                if recurrenceType == .selectedWeekdays || recurrenceType == .weekly {
                    WeekdaySelector(
                        selection: $selectedWeekdays,
                        allowsMultipleSelection: recurrenceType == .selectedWeekdays
                    )
                    .padding(.top, AppSpacing.xSmall)
                }
            }
        }
    }
}

private struct RoutineFormActions: View {
    let isCreateDisabled: Bool
    let onCancel: () -> Void
    let onCreate: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Spacer()

            Button("Vazgeç", role: .cancel, action: onCancel)
                .keyboardShortcut(.cancelAction)

            Button("Rutin Ekle", systemImage: "plus", action: onCreate)
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(isCreateDisabled)
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.medium)
        .background(.bar)
    }
}

private extension RoutineTimeOfDay {
    var title: LocalizedStringResource {
        switch self {
        case .morning: "Sabah"
        case .afternoon: "Öğleden sonra"
        case .evening: "Akşam"
        case .anytime: "Herhangi"
        }
    }
}

private extension RecurrenceType {
    var title: LocalizedStringResource {
        switch self {
        case .everyDay: "Her gün"
        case .weekdays: "Hafta içi"
        case .selectedWeekdays: "Seçili günler"
        case .weekly: "Haftalık"
        case .custom: "Özel"
        }
    }
}
