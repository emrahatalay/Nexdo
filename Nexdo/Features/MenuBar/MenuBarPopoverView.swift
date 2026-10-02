import SwiftData
import SwiftUI

/// Madde 23: ana pencereyi açmadan çalışma gününü yönetebilme.
struct MenuBarPopoverView: View {
    var body: some View {
        content
            .padding(AppSpacing.medium)
            .frame(width: 280)
    }

    @ViewBuilder
    private var content: some View {
        let timerService = AppEnvironment.shared.focusTimerService

        if let session = timerService.activeSession, let task = session.task {
            VStack(alignment: .leading, spacing: AppSpacing.small) {
                Text(task.title)
                    .font(AppTypography.body.bold())

                Text(formattedRemaining(session.remainingTime(at: timerService.tickDate)))
                    .font(AppTypography.timer)

                HStack(spacing: AppSpacing.small) {
                    Button(session.state == .paused ? "Devam Et" : "Duraklat") {
                        if session.state == .paused {
                            timerService.resume()
                        } else {
                            timerService.pause()
                        }
                    }
                    Button("Bitir") {
                        timerService.complete()
                    }
                }
                .buttonStyle(.bordered)

                if let next = nextTaskPreview(excluding: task.id) {
                    Divider()
                    Text("Sonraki")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                    Text(next.title)
                        .font(AppTypography.body)
                    if let duration = next.estimatedDuration {
                        Text("\(Int(duration / 60)) dk")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        } else {
            Text("Aktif bir odak oturumu yok")
                .foregroundStyle(.secondary)
        }
    }

    private func nextTaskPreview(excluding currentTaskID: UUID) -> TaskItem? {
        let context = AppEnvironment.shared.modelContainer.mainContext
        let today = Calendar.current.startOfDay(for: .now)
        let tasks = (try? context.fetch(FetchDescriptor<TaskItem>())) ?? []
        return tasks
            .filter { $0.plannedDate == today && $0.status == .planned && $0.id != currentTaskID }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
    }

    private func formattedRemaining(_ interval: TimeInterval) -> String {
        let clamped = max(interval, 0)
        return String(format: "%02d:%02d", Int(clamped) / 60, Int(clamped) % 60)
    }
}
