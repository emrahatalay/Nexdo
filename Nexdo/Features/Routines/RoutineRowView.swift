import SwiftUI

struct RoutineRowView: View {
    let routine: Routine
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isCompleted ? Color.accentColor : .secondary)
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCompleted ? "Tamamlandı" : "Tamamlanmadı")

            VStack(alignment: .leading, spacing: 2) {
                Text(routine.title)
                    .strikethrough(isCompleted)
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                Text("\(Int(routine.estimatedDuration / 60)) dk")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}
