import SwiftUI

/// Madde 19: utandırıcı/cezalandırıcı değil, nötr bir dil kullanılır.
struct PostponeReasonSheet: View {
    let task: TaskItem
    let onSelect: (PostponeReason) -> Void

    private let reasons: [(PostponeReason, String)] = [
        (.noEnergy, "Enerjim yok"),
        (.taskTooBig, "İş çok büyük"),
        (.unclearNextStep, "Ne yapacağım net değil"),
        (.somethingElseCameUp, "Başka iş çıktı"),
        (.environmentNotSuitable, "Ortam uygun değil"),
        (.other, "Diğer")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Neden?")
                .font(AppTypography.title)
            Text(task.title)
                .foregroundStyle(.secondary)

            VStack(spacing: AppSpacing.xSmall) {
                ForEach(reasons, id: \.0) { reason, label in
                    Button(label) { onSelect(reason) }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(AppSpacing.large)
        .frame(width: 360)
    }
}
