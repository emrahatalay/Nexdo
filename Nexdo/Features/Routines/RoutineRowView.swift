import SwiftUI

struct RoutineRowView: View {
    let routine: Routine
    let isCompleted: Bool
    let onToggle: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green : Color.secondary.opacity(0.08))
                        .frame(width: 36, height: 36)
                    Image(systemName: isCompleted ? "checkmark" : "circle")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isCompleted ? .white : .secondary)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Tamamlandı, geri al" : "Tamamlandı olarak işaretle")

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(routine.title)
                    .font(.body.weight(.semibold))
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                HStack(spacing: AppSpacing.small) {
                    Label("\(Int(routine.estimatedDuration / 60)) dk", systemImage: "clock")
                    Label(timeOfDayTitle, systemImage: timeOfDayIcon)
                }
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(isCompleted ? "Tamamlandı" : "Sırada")
                .font(AppTypography.overline)
                .foregroundStyle(isCompleted ? .green : .secondary)
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(
                    (isCompleted ? Color.green : Color.secondary).opacity(0.09),
                    in: Capsule()
                )
        }
        .padding(.vertical, AppSpacing.small)
        .animation(reduceMotion ? nil : .snappy(duration: 0.28), value: isCompleted)
    }

    private var timeOfDayTitle: String {
        switch routine.timeOfDay {
        case .morning: "Sabah"
        case .afternoon: "Öğleden sonra"
        case .evening: "Akşam"
        case .anytime: "Gün içinde"
        }
    }

    private var timeOfDayIcon: String {
        switch routine.timeOfDay {
        case .morning: "sunrise"
        case .afternoon: "sun.max"
        case .evening: "sunset"
        case .anytime: "clock"
        }
    }
}
