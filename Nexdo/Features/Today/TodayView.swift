import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    @State private var showPostponeSheet = false
    @State private var taskToPostpone: TaskItem?

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(SidebarSection.today.title)
        .task {
            if viewModel == nil {
                viewModel = TodayViewModel(modelContext: modelContext)
            } else {
                viewModel?.refresh()
            }
        }
        .sheet(isPresented: $showPostponeSheet) {
            if let taskToPostpone {
                PostponeReasonSheet(task: taskToPostpone) { reason in
                    viewModel?.recordPostponement(for: taskToPostpone, reason: reason)
                    showPostponeSheet = false
                }
            }
        }
    }

    @ViewBuilder
    private func content(_ viewModel: TodayViewModel) -> some View {
        if let current = viewModel.currentTask {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Text("BUGÜN")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    Text("ŞİMDİ")
                        .font(AppTypography.caption.bold())
                        .foregroundStyle(Color.accentColor)

                    Text(current.title)
                        .font(.largeTitle.bold())

                    if let start = current.scheduledStart, let end = current.scheduledEnd {
                        Text("\(start.formatted(date: .omitted, time: .shortened)) → \(end.formatted(date: .omitted, time: .shortened))")
                            .foregroundStyle(.secondary)
                    }

                    if let firstAction = current.firstAction {
                        Label(firstAction, systemImage: "arrow.forward.circle")
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: AppSpacing.large) {
                        Button(current.status == .active ? "Odaklan" : "BAŞLADIM") {
                            start(current)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .keyboardShortcut(.return, modifiers: .command)

                        if current.status != .active {
                            Button("Şimdi yapamıyorum") {
                                taskToPostpone = current
                                showPostponeSheet = true
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, AppSpacing.small)
                }
                .padding(AppSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))

                if let next = viewModel.nextTask {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sonraki")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                        Text(next.title)
                            .font(AppTypography.body)
                        if let start = next.scheduledStart, let duration = next.estimatedDuration {
                            Text("\(start.formatted(date: .omitted, time: .shortened)) · \(Int(duration / 60)) dk")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()
            }
            .padding(AppSpacing.large)
        } else {
            ContentUnavailableView {
                Label("Bugün için plan hazırlanmadı.", systemImage: "sun.max")
            } description: {
                Text("Akşam Planı'ndan yarınını hazırla.")
            } actions: {
                Button("Bugünü Planla") {
                    AppEnvironment.shared.navigationState.selection = .planning
                }
            }
        }
    }

    private func start(_ task: TaskItem) {
        if task.status != .active {
            AppEnvironment.shared.focusTimerService.start(for: task)
            viewModel?.refresh()
        }
        AppEnvironment.shared.navigationState.selection = .focus
    }
}
