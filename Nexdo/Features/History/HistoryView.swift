import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HistoryViewModel?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(SidebarSection.history.title)
        .task {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            } else {
                viewModel?.refresh()
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: HistoryViewModel) -> some View {
        if viewModel.days.isEmpty {
            ContentUnavailableView(
                "Henüz geçmiş veri yok.",
                systemImage: "clock.arrow.circlepath",
                description: Text("Tamamladığın günler burada birikecek.")
            )
        } else {
            List {
                if let summary = viewModel.estimationInsight.summary {
                    Section {
                        Label(summary, systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundStyle(.secondary)
                    }
                }

                ForEach(viewModel.days) { day in
                    Section(dateLabel(day.date)) {
                        dayHeader(day)

                        ForEach(day.completedSessions) { session in
                            sessionRow(session, isStopped: false)
                        }
                        ForEach(day.stoppedSessions) { session in
                            sessionRow(session, isStopped: true)
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func dayHeader(_ day: HistoryViewModel.DaySummary) -> some View {
        HStack(spacing: AppSpacing.large) {
            metric("Tamamlanan", "\(day.completedSessions.count)")
            metric("Durdurulan", "\(day.stoppedSessions.count)")
            metric("Odak", "\(day.totalActualMinutes) dk")
            if day.routineExpected > 0 {
                metric("Rutin", "\(day.routineCompleted)/\(day.routineExpected)")
            }
            if day.postponementCount > 0 {
                metric("Erteleme", "\(day.postponementCount)")
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(AppTypography.body.bold())
        }
    }

    private func sessionRow(_ session: HistoryViewModel.SessionRecord, isStopped: Bool) -> some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: isStopped ? "pause.circle" : "checkmark.circle.fill")
                .foregroundStyle(isStopped ? .orange : Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.taskTitle)
                Text("Tahmin: \(session.estimatedMinutes) dk · Gerçek: \(session.actualMinutes) dk")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func dateLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Bugün" }
        if Calendar.current.isDateInYesterday(date) { return "Dün" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
