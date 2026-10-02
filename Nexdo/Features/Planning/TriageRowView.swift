import SwiftUI

/// Madde 7: "Bu iş önemli mi?" / "Bu iş acil mi?" — iki soru cevaplanınca quadrant otomatik belirlenir.
struct TriageRowView: View {
    let task: TaskItem
    let onClassify: (_ isImportant: Bool, _ isUrgent: Bool) -> Void

    @State private var isImportant: Bool?
    @State private var isUrgent: Bool?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text(task.title)
                    .font(.body.weight(.semibold))
                Spacer()
                if let outcome {
                    Label(outcome.title, systemImage: outcome.systemImage)
                        .font(AppTypography.caption.weight(.semibold))
                        .foregroundStyle(outcome.color)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.large) {
                    question(number: 1, title: "Önemli mi?", hint: "Hedeflerine katkı sağlar mı?", selection: $isImportant)
                    question(number: 2, title: "Acil mi?", hint: "Yakın bir son tarihi var mı?", selection: $isUrgent)
                }
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    question(number: 1, title: "Önemli mi?", hint: "Hedeflerine katkı sağlar mı?", selection: $isImportant)
                    question(number: 2, title: "Acil mi?", hint: "Yakın bir son tarihi var mı?", selection: $isUrgent)
                }
            }
        }
        .padding(.vertical, AppSpacing.small)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isImportant)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isUrgent)
        .onChange(of: isImportant) { _, _ in classifyIfReady() }
        .onChange(of: isUrgent) { _, _ in classifyIfReady() }
    }

    private func question(
        number: Int,
        title: LocalizedStringKey,
        hint: LocalizedStringKey,
        selection: Binding<Bool?>
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack(spacing: AppSpacing.xSmall) {
                Text(number, format: .number)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 18, height: 18)
                    .background(Color.accentColor, in: Circle())
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(AppTypography.caption.weight(.semibold))
                    Text(hint)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            HStack(spacing: AppSpacing.xSmall) {
                TriageChoiceButton(title: "Evet", isSelected: selection.wrappedValue == true) {
                    selection.wrappedValue = true
                }
                TriageChoiceButton(title: "Hayır", isSelected: selection.wrappedValue == false) {
                    selection.wrappedValue = false
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func classifyIfReady() {
        guard let isImportant, let isUrgent else { return }
        onClassify(isImportant, isUrgent)
    }

    private var outcome: (title: LocalizedStringKey, systemImage: String, color: Color)? {
        guard let isImportant, let isUrgent else { return nil }
        switch EisenhowerQuadrant.classify(isImportant: isImportant, isUrgent: isUrgent) {
        case .doNow: return ("Yarına eklenir", "arrow.right.circle.fill", .green)
        case .schedule: return ("Yarına eklenir", "calendar.badge.plus", .blue)
        case .delegate: return ("Devret", "person.2.fill", .orange)
        case .eliminate: return ("Ele", "trash.fill", .secondary)
        case .unset: return nil
        }
    }
}

private struct TriageChoiceButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                Text(title)
            }
            .frame(minWidth: 64)
        }
        .buttonStyle(.bordered)
        .tint(isSelected ? .accentColor : .secondary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
