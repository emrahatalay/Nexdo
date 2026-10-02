import SwiftData
import SwiftUI

struct PlanningView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: PlanningViewModel?
    @State private var showBlockingIssues = false
    @State private var showCapacityConfirmation = false

    var body: some View {
        Group {
            if let viewModel {
                planningContent(viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(SidebarSection.planning.title)
        .task {
            if viewModel == nil {
                viewModel = PlanningViewModel(modelContext: modelContext)
            }
        }
    }

    @ViewBuilder
    private func planningContent(_ viewModel: PlanningViewModel) -> some View {
        if viewModel.dailyPlan.isLocked {
            lockedSummary(viewModel)
        } else if viewModel.inboxTasks.isEmpty && viewModel.tomorrowTasks.isEmpty {
            ContentUnavailableView(
                "Yarın için henüz bir şey seçmedin.",
                systemImage: "moon.stars",
                description: Text("İş Havuzu'ndaki görevleri değerlendirip yarına taşı.")
            )
        } else {
            editableForm(viewModel)
        }
    }

    private func editableForm(_ viewModel: PlanningViewModel) -> some View {
        List {
            Section("Kapasite") {
                CapacityBarView(
                    capacity: viewModel.capacityResult,
                    onAvailableChange: viewModel.updateAvailableMinutes,
                    onBufferChange: viewModel.updateBufferMinutes
                )
            }

            if !viewModel.inboxTasks.isEmpty {
                Section("Değerlendirilecek İşler") {
                    ForEach(viewModel.inboxTasks) { task in
                        TriageRowView(task: task) { isImportant, isUrgent in
                            viewModel.classify(task, isImportant: isImportant, isUrgent: isUrgent)
                        }
                    }
                }
            }

            if !viewModel.tomorrowTasks.isEmpty {
                Section("Yarının Planı") {
                    ForEach(viewModel.tomorrowTasks) { task in
                        PlannedTaskRowView(
                            task: task,
                            onSetTimebox: { viewModel.setTimebox(task, minutes: $0) },
                            onSetFirstAction: { viewModel.setFirstAction(task, action: $0) },
                            onRemove: { viewModel.removeFromTomorrow(task) }
                        )
                    }
                    .onMove(perform: viewModel.move)
                }

                Section("Zaman Çizelgesi") {
                    TimelineView(blocks: viewModel.timelineBlocks)
                }
            }

            Section {
                Button("Yarını Hazırla") {
                    attemptLock(viewModel)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
        .listStyle(.inset)
        .alert("Yarın için plan eksik", isPresented: $showBlockingIssues) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel.blockingIssues.map(\.message).joined(separator: "\n"))
        }
        .alert("Kapasite aşıldı", isPresented: $showCapacityConfirmation) {
            Button("Yine de Kilitle", role: .destructive) { viewModel.lockPlan() }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text(viewModel.capacityWarningMessage ?? "")
        }
    }

    private func attemptLock(_ viewModel: PlanningViewModel) {
        guard viewModel.blockingIssues.isEmpty else {
            showBlockingIssues = true
            return
        }
        if viewModel.capacityResult.overCapacity {
            showCapacityConfirmation = true
        } else {
            viewModel.lockPlan()
        }
    }

    private func lockedSummary(_ viewModel: PlanningViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                Label("Yarının planı hazır", systemImage: "checkmark.seal.fill")
                    .font(AppTypography.title)

                Text("\(viewModel.tomorrowTasks.count) iş planlandı.")
                    .foregroundStyle(.secondary)

                TimelineView(blocks: viewModel.timelineBlocks)

                Button("Kilidi Kaldır", role: .destructive) {
                    viewModel.unlockPlan()
                }
            }
            .padding(AppSpacing.large)
        }
    }
}
