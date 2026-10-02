import SwiftData
import SwiftUI

struct PlanningView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: PlanningViewModel?
    @State private var showBlockingIssues = false
    @State private var showCapacityConfirmation = false
    @State private var showDayReview = false

    var body: some View {
        Group {
            if let viewModel {
                if viewModel.dailyPlan.isLocked {
                    PlanningLockedView(viewModel: viewModel)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    PlanningWorkspaceView(
                        viewModel: viewModel,
                        onFinalize: { attemptLock(viewModel) }
                    )
                    .transition(.opacity)
                }
            } else {
                ProgressView("Plan hazırlanıyor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppBackground())
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.4), value: viewModel?.dailyPlan.isLocked)
        .navigationTitle(SidebarSection.planning.title)
        .toolbar {
            ToolbarItem {
                Button {
                    showDayReview = true
                } label: {
                    Label("Günü Değerlendir", systemImage: "chart.bar.doc.horizontal")
                }
                .help("Bugünün kısa özetini aç")
            }
        }
        .task {
            if viewModel == nil {
                viewModel = PlanningViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $showDayReview) {
            DayReviewSheet(statistics: todaysStatistics()) {
                showDayReview = false
            }
        }
        .alert("Yarın için plan eksik", isPresented: $showBlockingIssues) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(viewModel?.blockingIssues.map(\.message).joined(separator: "\n") ?? "")
        }
        .alert("Kapasite aşıldı", isPresented: $showCapacityConfirmation) {
            Button("Yine de Hazırla", role: .destructive) { viewModel?.lockPlan() }
            Button("Planı Düzenle", role: .cancel) {}
        } message: {
            Text(viewModel?.capacityWarningMessage ?? "")
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

    private func todaysStatistics() -> DayStatistics {
        let today = Calendar.current.startOfDay(for: .now)
        let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        let allSessions = (try? modelContext.fetch(FetchDescriptor<FocusSession>())) ?? []
        let allRoutines = (try? modelContext.fetch(FetchDescriptor<Routine>())) ?? []
        let allCompletions = (try? modelContext.fetch(FetchDescriptor<RoutineCompletion>())) ?? []
        return StatisticsService().dayStatistics(
            for: today,
            allTasks: allTasks,
            allSessions: allSessions,
            allRoutines: allRoutines,
            allCompletions: allCompletions,
            scheduler: RoutineScheduler()
        )
    }
}

private struct PlanningWorkspaceView: View {
    let viewModel: PlanningViewModel
    let onFinalize: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                PlanningHeroView(
                    date: viewModel.tomorrowDate,
                    inboxCount: viewModel.inboxTasks.count,
                    plannedCount: viewModel.tomorrowTasks.count,
                    readyCount: viewModel.tomorrowTasks.filter { $0.estimatedDuration != nil }.count
                )

                PlanningGuideView(
                    hasTriage: !viewModel.inboxTasks.isEmpty,
                    hasTasks: !viewModel.tomorrowTasks.isEmpty,
                    isReady: viewModel.blockingIssues.isEmpty
                )

                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        AppSectionHeader(
                            "Günün sınırlarını belirle",
                            subtitle: "Önce gerçekçi çalışma süreni ve beklenmeyen işler için tamponu ayarla.",
                            systemImage: "gauge.with.dots.needle.50percent"
                        )
                        CapacityBarView(
                            capacity: viewModel.capacityResult,
                            onAvailableChange: viewModel.updateAvailableMinutes,
                            onBufferChange: viewModel.updateBufferMinutes
                        )
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppSpacing.large) {
                        PlanningTaskColumn(viewModel: viewModel)
                            .frame(maxWidth: .infinity, alignment: .top)
                        PlanningTimelineCard(blocks: viewModel.timelineBlocks)
                            .frame(width: 330, alignment: .top)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        PlanningTaskColumn(viewModel: viewModel)
                        PlanningTimelineCard(blocks: viewModel.timelineBlocks)
                    }
                }

                PlanningFinalizeCard(
                    taskCount: viewModel.tomorrowTasks.count,
                    blockingIssues: viewModel.blockingIssues,
                    isOverCapacity: viewModel.capacityResult.overCapacity,
                    onFinalize: onFinalize
                )
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: viewModel.inboxTasks.count)
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: viewModel.tomorrowTasks.count)
    }
}

private struct PlanningHeroView: View {
    let date: Date
    let inboxCount: Int
    let plannedCount: Int
    let readyCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.large) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(AppTypography.overline)
                    .foregroundStyle(.tint)
                    .textCase(.uppercase)
                Text("Yarını sakin bir zihinle kur")
                    .font(AppTypography.pageTitle)
                Text("İşleri önceliklendir, sürelerini netleştir ve uygulanabilir bir güne dönüştür.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppSpacing.medium)

            HStack(spacing: AppSpacing.small) {
                PlanningHeroMetric(value: inboxCount, label: "Bekleyen", color: .orange)
                PlanningHeroMetric(value: plannedCount, label: "Planlanan", color: .accentColor)
                PlanningHeroMetric(value: readyCount, label: "Hazır", color: .green)
            }
        }
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.16), Color.accentColor.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 72))
                .foregroundStyle(Color.accentColor.opacity(0.07))
                .padding(AppSpacing.medium)
                .accessibilityHidden(true)
        }
    }
}

private struct PlanningHeroMetric: View {
    let value: Int
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xxSmall) {
            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 68)
        .padding(.vertical, AppSpacing.small)
        .background(.background.opacity(0.6), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct PlanningGuideView: View {
    let hasTriage: Bool
    let hasTasks: Bool
    let isReady: Bool

    var body: some View {
        HStack(spacing: 0) {
            PlanningGuideStep(number: 1, title: "Kapasite", isComplete: true, isCurrent: false)
            PlanningGuideConnector(isComplete: !hasTriage)
            PlanningGuideStep(number: 2, title: "Önceliklendir", isComplete: !hasTriage, isCurrent: hasTriage)
            PlanningGuideConnector(isComplete: hasTasks)
            PlanningGuideStep(number: 3, title: "Netleştir", isComplete: isReady, isCurrent: !hasTriage && !isReady)
            PlanningGuideConnector(isComplete: isReady)
            PlanningGuideStep(number: 4, title: "Hazırla", isComplete: false, isCurrent: isReady)
        }
        .padding(.horizontal, AppSpacing.medium)
        .accessibilityElement(children: .combine)
    }
}

private struct PlanningGuideStep: View {
    let number: Int
    let title: LocalizedStringKey
    let isComplete: Bool
    let isCurrent: Bool

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            ZStack {
                Circle()
                    .fill(isComplete || isCurrent ? Color.accentColor : Color.secondary.opacity(0.13))
                    .frame(width: 30, height: 30)
                Image(systemName: isComplete ? "checkmark" : "\(number).circle.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isComplete || isCurrent ? .white : .secondary)
            }
            Text(title)
                .font(AppTypography.caption.weight(isCurrent ? .semibold : .regular))
                .foregroundStyle(isCurrent ? .primary : .secondary)
        }
    }
}

private struct PlanningGuideConnector: View {
    let isComplete: Bool

    var body: some View {
        Capsule()
            .fill(isComplete ? Color.accentColor : Color.secondary.opacity(0.16))
            .frame(maxWidth: .infinity)
            .frame(height: 3)
            .padding(.horizontal, AppSpacing.xSmall)
            .offset(y: -11)
    }
}

private struct PlanningTaskColumn: View {
    let viewModel: PlanningViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.large) {
            if !viewModel.inboxTasks.isEmpty {
                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        AppSectionHeader(
                            "Önceliklendir",
                            subtitle: "İki kısa yanıt ver; uygun işler otomatik olarak yarının planına geçsin.",
                            systemImage: "square.grid.2x2"
                        )
                        ForEach(viewModel.inboxTasks) { task in
                            TriageRowView(task: task) { isImportant, isUrgent in
                                viewModel.classify(task, isImportant: isImportant, isUrgent: isUrgent)
                            }
                            if task.id != viewModel.inboxTasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }

            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.medium) {
                    AppSectionHeader(
                        "Yarının odak listesi",
                        subtitle: "Her iş için süre ve başlayacağın ilk somut hareketi belirle. Sıralamayı sürükleyerek değiştirebilirsin.",
                        systemImage: "list.bullet.rectangle.portrait"
                    )

                    if viewModel.tomorrowTasks.isEmpty {
                        PlanningEmptyTasksView(hasInboxTasks: !viewModel.inboxTasks.isEmpty)
                    } else {
                        ForEach(viewModel.tomorrowTasks) { task in
                            PlannedTaskRowView(
                                task: task,
                                onSetTimebox: { viewModel.setTimebox(task, minutes: $0) },
                                onSetFirstAction: { viewModel.setFirstAction(task, action: $0) },
                                onRemove: { viewModel.removeFromTomorrow(task) }
                            )
                            if task.id != viewModel.tomorrowTasks.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct PlanningEmptyTasksView: View {
    let hasInboxTasks: Bool

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: hasInboxTasks ? "arrow.up.left.and.arrow.down.right" : "tray")
                .font(.title)
                .foregroundStyle(.secondary)
            Text(hasInboxTasks ? "Önce bekleyen işleri değerlendir" : "Planlanacak iş bulunmuyor")
                .font(AppTypography.sectionTitle)
            Text(hasInboxTasks ? "Önemli ve acil kararlarını verdikçe uygun işler burada görünecek." : "İş Havuzu'na yeni görev eklediğinde burada planlayabilirsin.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xLarge)
    }
}

private struct PlanningTimelineCard: View {
    let blocks: [TimelineBlock]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Günün akışı",
                    subtitle: "Saat 09.00'dan başlayan otomatik zaman çizelgen.",
                    systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
                )
                ScheduleTimelineView(blocks: blocks)
            }
        }
    }
}

private struct PlanningFinalizeCard: View {
    let taskCount: Int
    let blockingIssues: [PlanningValidationIssue]
    let isOverCapacity: Bool
    let onFinalize: () -> Void

    var body: some View {
        AppCard {
            HStack(alignment: .center, spacing: AppSpacing.large) {
                Image(systemName: blockingIssues.isEmpty ? "checkmark.seal.fill" : "checklist.unchecked")
                    .font(.largeTitle)
                    .foregroundStyle(blockingIssues.isEmpty ? Color.green : Color.orange)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(blockingIssues.isEmpty ? "Planın hazır görünüyor" : "Bitirmeden önce birkaç adım var")
                        .font(AppTypography.title)
                    if blockingIssues.isEmpty {
                        Text(isOverCapacity ? "Kapasite aşımını onaylayarak planı tamamlayabilirsin." : "Yarın için \(taskCount) işi netleştirdin. Planı sabitleyebilirsin.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(blockingIssues, id: \.message) { issue in
                            Label(issue.message, systemImage: "circle.fill")
                                .font(AppTypography.caption)
                                .foregroundStyle(.secondary)
                                .symbolRenderingMode(.hierarchical)
                        }
                    }
                }

                Spacer(minLength: AppSpacing.medium)

                Button(action: onFinalize) {
                    Label("Yarını Hazırla", systemImage: "lock.fill")
                        .padding(.horizontal, AppSpacing.small)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(taskCount == 0)
                .keyboardShortcut(.return, modifiers: [.command])
            }
        }
    }
}

private struct PlanningLockedView: View {
    let viewModel: PlanningViewModel

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AppCard {
                    HStack(spacing: AppSpacing.large) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.green)
                            .symbolEffect(.bounce, value: viewModel.dailyPlan.isLocked)
                        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                            Text("Yarın hazır")
                                .font(AppTypography.pageTitle)
                            Text("\(viewModel.tomorrowTasks.count) iş, rutinler ve tampon süreyle birlikte planlandı.")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Planı Düzenle", systemImage: "pencil") {
                            viewModel.unlockPlan()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }

                AppCard {
                    VStack(alignment: .leading, spacing: AppSpacing.medium) {
                        AppSectionHeader(
                            "Yarının zaman çizelgesi",
                            subtitle: "Güne başladığında sıradaki işi düşünmene gerek kalmayacak.",
                            systemImage: "calendar.day.timeline.left"
                        )
                        ScheduleTimelineView(blocks: viewModel.timelineBlocks)
                    }
                }
            }
        }
    }
}
