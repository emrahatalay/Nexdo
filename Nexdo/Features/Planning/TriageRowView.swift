import SwiftUI

/// Madde 7: "Bu iş önemli mi?" / "Bu iş acil mi?" — iki soru cevaplanınca quadrant otomatik belirlenir.
struct TriageRowView: View {
    let task: TaskItem
    let onClassify: (_ isImportant: Bool, _ isUrgent: Bool) -> Void

    @State private var isImportant: Bool?
    @State private var isUrgent: Bool?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(task.title)
                .font(AppTypography.body)

            HStack(spacing: AppSpacing.large) {
                question(title: "Önemli mi?", selection: $isImportant)
                question(title: "Acil mi?", selection: $isUrgent)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
        .onChange(of: isImportant) { _, _ in classifyIfReady() }
        .onChange(of: isUrgent) { _, _ in classifyIfReady() }
    }

    private func question(title: String, selection: Binding<Bool?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: AppSpacing.xSmall) {
                Button("Evet") { selection.wrappedValue = true }
                    .buttonStyle(.bordered)
                    .tint(selection.wrappedValue == true ? .accentColor : nil)
                    .accessibilityLabel("\(task.title): \(title) Evet")
                Button("Hayır") { selection.wrappedValue = false }
                    .buttonStyle(.bordered)
                    .tint(selection.wrappedValue == false ? .accentColor : nil)
                    .accessibilityLabel("\(task.title): \(title) Hayır")
            }
        }
    }

    private func classifyIfReady() {
        guard let isImportant, let isUrgent else { return }
        onClassify(isImportant, isUrgent)
    }
}
