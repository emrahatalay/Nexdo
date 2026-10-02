import SwiftUI

/// Madde 27: Akşam Planı'na geçmeden önce kısa bir gün değerlendirmesi.
struct DayReviewSheet: View {
    let statistics: DayStatistics
    let onContinue: () -> Void

    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            Text("Bugün")
                .font(AppTypography.title)

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                row("Tamamlanan", "\(statistics.completedCount) / \(statistics.totalPlannedTasks)")
                row("Planlanan", "\(statistics.plannedMinutes) dk")
                row("Gerçek", "\(statistics.actualMinutes) dk")
                row("Durdurulan", "\(statistics.stoppedCount)")
                if statistics.routineExpectedCount > 0 {
                    row("Rutin", "\(statistics.routineCompletedCount) / \(statistics.routineExpectedCount)")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text("Bugünden yarına taşınması gereken bir şey var mı?")
                    .font(AppTypography.body)
                TextField("Not (opsiyonel) — İş Havuzu'na eklemeyi unutma", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3)
            }

            Button("Akşam Planına Geç") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
        .padding(AppSpacing.large)
        .frame(minWidth: 340, idealWidth: 440, maxWidth: 540)
        .background(AppBackground())
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}
