import Foundation
import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: TodayViewModel?
    @State private var showPostponeSheet = false
    @State private var showTaskPicker = false
    @State private var showTaskSwitcher = false
    @State private var showAbandonConfirmation = false
    @State private var taskToPostpone: TaskItem?

    private var focusTimerService: FocusTimerService {
        AppEnvironment.shared.focusTimerService
    }

    var body: some View {
        Group {
            if let viewModel {
                TodayContent(
                    tasks: viewModel.todayTasks,
                    currentTask: viewModel.currentTask,
                    nextTask: viewModel.nextTask,
                    activeSession: focusTimerService.activeSession,
                    routines: viewModel.todayRoutines,
                    completedRoutineIDs: viewModel.completedRoutineIDs,
                    onStart: start,
                    onPostpone: { task in
                        taskToPostpone = task
                        showPostponeSheet = true
                    },
                    onAddTask: { showTaskPicker = true },
                    onSwitchTask: { showTaskSwitcher = true },
                    onAbandonTask: { showAbandonConfirmation = true },
                    onRemoveTask: viewModel.removeFromToday,
                    onToggleRoutine: viewModel.toggleRoutineCompletion
                )
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppBackground())
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel?.currentTask?.id)
        .navigationTitle(SidebarSection.today.title)
        .toolbar {
            ToolbarItem {
                Button("Bugüne İş Ekle", systemImage: "plus") {
                    showTaskPicker = true
                }
            }
        }
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
        .sheet(isPresented: $showTaskPicker) {
            if let viewModel {
                TodayTaskPickerSheet(
                    tasks: viewModel.availableTasks,
                    onAdd: { task in
                        viewModel.addToToday(task)
                    }
                )
            }
        }
        .sheet(isPresented: $showTaskSwitcher) {
            if let viewModel {
                FocusTaskSwitcherSheet(
                    tasks: viewModel.todayTasks.filter { $0.id != focusTimerService.activeSession?.task?.id },
                    onSwitch: switchToTask
                )
            }
        }
        .confirmationDialog(
            "Bu iş şimdilik geçilsin mi?",
            isPresented: $showAbandonConfirmation,
            titleVisibility: .visible
        ) {
            Button("Şimdilik Geç") {
                if focusTimerService.deferActiveTask() {
                    viewModel?.refresh()
                }
            }
            Button("Devam Et", role: .cancel) {}
        } message: {
            Text("İş bugünün planında kalacak, listenin sonuna taşınacak ve sıradaki iş öne gelecek. Bu seçenek yalnızca ilk %10 içinde kullanılabilir.")
        }
        .alert(
            "Değişiklik kaydedilemedi",
            isPresented: Binding(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button("Tamam") {
                viewModel?.errorMessage = nil
            }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }

    private func start(_ task: TaskItem) {
        if task.status != .active {
            AppEnvironment.shared.focusTimerService.start(for: task)
            viewModel?.refresh()
        }
        AppEnvironment.shared.navigationState.selection = .focus
    }

    private func switchToTask(_ task: TaskItem) {
        if focusTimerService.switchTo(task) {
            viewModel?.refresh()
            showTaskSwitcher = false
            AppEnvironment.shared.navigationState.selection = .focus
        }
    }
}

private struct TodayContent: View {
    let tasks: [TaskItem]
    let currentTask: TaskItem?
    let nextTask: TaskItem?
    let activeSession: FocusSession?
    let routines: [Routine]
    let completedRoutineIDs: Set<UUID>
    let onStart: (TaskItem) -> Void
    let onPostpone: (TaskItem) -> Void
    let onAddTask: () -> Void
    let onSwitchTask: () -> Void
    let onAbandonTask: () -> Void
    let onRemoveTask: (TaskItem) -> Void
    let onToggleRoutine: (Routine) -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var plannedMinutes: Int {
        tasks.reduce(0) { $0 + Int(($1.estimatedDuration ?? 0) / 60) }
    }

    private var completedRoutineCount: Int {
        routines.count { completedRoutineIDs.contains($0.id) }
    }

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                TodayHeroView(
                    taskCount: tasks.count,
                    plannedMinutes: plannedMinutes,
                    routineCount: routines.count,
                    completedRoutineCount: completedRoutineCount,
                    onAddTask: onAddTask
                )

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: AppSpacing.large) {
                        TodayPrimaryFocus(
                            currentTask: currentTask,
                            nextTask: nextTask,
                            activeSession: activeSession,
                            onStart: onStart,
                            onPostpone: onPostpone,
                            onSwitchTask: onSwitchTask,
                            onAbandonTask: onAbandonTask,
                            onAddTask: onAddTask
                        )
                        .frame(maxWidth: .infinity, alignment: .top)

                        TodayScheduleCard(tasks: tasks, currentTaskID: currentTask?.id)
                            .frame(width: 340, alignment: .top)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        TodayPrimaryFocus(
                            currentTask: currentTask,
                            nextTask: nextTask,
                            activeSession: activeSession,
                            onStart: onStart,
                            onPostpone: onPostpone,
                            onSwitchTask: onSwitchTask,
                            onAbandonTask: onAbandonTask,
                            onAddTask: onAddTask
                        )
                        TodayScheduleCard(tasks: tasks, currentTaskID: currentTask?.id)
                    }
                }

                if !routines.isEmpty {
                    TodayRoutinesCard(
                        routines: routines,
                        completedRoutineIDs: completedRoutineIDs,
                        onToggle: onToggleRoutine
                    )
                }

                if let currentTask {
                    TodayPlanCard(
                        tasks: tasks,
                        currentTaskID: currentTask.id,
                        onAddTask: onAddTask,
                        onRemoveTask: onRemoveTask
                    )
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.38), value: currentTask?.id)
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: completedRoutineIDs.count)
    }
}

private struct TodayHeroView: View {
    let taskCount: Int
    let plannedMinutes: Int
    let routineCount: Int
    let completedRoutineCount: Int
    let onAddTask: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppSpacing.xLarge) {
                title
                Spacer(minLength: AppSpacing.medium)
                metrics
                addButton
            }

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                title
                metrics
                addButton
            }
        }
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.16), Color.blue.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sun.max.fill")
                .font(.system(size: 88))
                .foregroundStyle(Color.orange.opacity(0.055))
                .padding(AppSpacing.medium)
                .accessibilityHidden(true)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(AppTypography.overline)
                .foregroundStyle(.tint)
                .textCase(.uppercase)
            Text("Bugünün odağı")
                .font(AppTypography.pageTitle)
            Text("Tek bir sonraki adıma odaklan; günün geri kalanı zaten sırada.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metrics: some View {
        HStack(spacing: AppSpacing.small) {
            TodayMetric(value: taskCount, label: "Kalan iş", color: .accentColor)
            TodayMetric(value: plannedMinutes, label: "Planlanan dk", color: .blue)
            TodayMetric(value: completedRoutineCount, total: routineCount, label: "Rutin", color: .green)
        }
    }

    private var addButton: some View {
        Button("İş Ekle", systemImage: "plus", action: onAddTask)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

private struct TodayMetric: View {
    let value: Int
    var total: Int?
    let label: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: AppSpacing.xxSmall) {
            if let total {
                Text("\(value)/\(total)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            } else {
                Text(value, format: .number)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())
            }
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 76)
        .padding(.vertical, AppSpacing.small)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct TodayPrimaryFocus: View {
    let currentTask: TaskItem?
    let nextTask: TaskItem?
    let activeSession: FocusSession?
    let onStart: (TaskItem) -> Void
    let onPostpone: (TaskItem) -> Void
    let onSwitchTask: () -> Void
    let onAbandonTask: () -> Void
    let onAddTask: () -> Void

    var body: some View {
        if let currentTask {
            CurrentTaskCard(
                task: currentTask,
                nextTaskTitle: nextTask?.title,
                activeSession: activeSession?.task?.id == currentTask.id ? activeSession : nil,
                onStart: { onStart(currentTask) },
                onPostpone: { onPostpone(currentTask) },
                onSwitchTask: onSwitchTask,
                onAbandonTask: onAbandonTask
            )
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
        } else {
            EmptyTodayCard(onAddTask: onAddTask)
                .transition(.opacity)
        }
    }
}

private struct TodayScheduleCard: View {
    let tasks: [TaskItem]
    let currentTaskID: UUID?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Günün akışı",
                    subtitle: "Planındaki işlerin zaman sırası.",
                    systemImage: "calendar.day.timeline.left"
                )

                if tasks.isEmpty {
                    VStack(spacing: AppSpacing.small) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                        Text("Henüz bir akış yok")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xLarge)
                } else {
                    VStack(spacing: 0) {
                        ForEach(tasks) { task in
                            TodayScheduleRow(task: task, isCurrent: task.id == currentTaskID)
                            if task.id != tasks.last?.id {
                                Divider().padding(.leading, 54)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct TodayScheduleRow: View {
    let task: TaskItem
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(task.scheduledStart ?? .now, format: .dateTime.hour().minute())
                .font(AppTypography.caption.monospacedDigit())
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                .frame(width: 44, alignment: .leading)
            Capsule()
                .fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.2))
                .frame(width: 3, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(isCurrent ? .semibold : .regular))
                    .lineLimit(1)
                if let duration = task.estimatedDuration {
                    Text("\(Int(duration / 60)) dakika")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if isCurrent {
                Image(systemName: "scope")
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse)
                    .accessibilityLabel("Şimdiki iş")
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}

private struct TodayRoutinesCard: View {
    let routines: [Routine]
    let completedRoutineIDs: Set<UUID>
    let onToggle: (Routine) -> Void

    private var completedCount: Int {
        routines.count { completedRoutineIDs.contains($0.id) }
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(alignment: .top, spacing: AppSpacing.medium) {
                    AppSectionHeader(
                        "Bugünkü rutinler",
                        subtitle: "Günün akışını bozmadan küçük adımları tamamla.",
                        systemImage: "checklist"
                    )

                    Spacer(minLength: AppSpacing.small)

                    Text("\(completedCount) / \(routines.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(completedCount == routines.count ? Color.green : Color.secondary)
                        .monospacedDigit()
                        .accessibilityLabel("\(routines.count) rutinden \(completedCount) tanesi tamamlandı")
                }

                ProgressView(value: Double(completedCount), total: Double(routines.count))
                    .tint(completedCount == routines.count ? .green : .accentColor)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    ForEach(routines) { routine in
                        TodayRoutineRow(
                            routine: routine,
                            isCompleted: completedRoutineIDs.contains(routine.id),
                            onToggle: { onToggle(routine) }
                        )

                        if routine.id != routines.last?.id {
                            Divider()
                                .padding(.leading, 38)
                        }
                    }
                }
            }
        }
    }
}

private struct TodayRoutineRow: View {
    let routine: Routine
    let isCompleted: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isCompleted ? Color.green : Color.secondary)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(routine.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(isCompleted ? .secondary : .primary)
                        .strikethrough(isCompleted)

                    HStack(spacing: AppSpacing.small) {
                        Label("\(Int(routine.estimatedDuration / 60)) dk", systemImage: "clock")
                        Text(timeOfDayTitle)
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: AppSpacing.small)

                if isCompleted {
                    Text("Tamamlandı")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, AppSpacing.small)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(routine.title)
        .accessibilityValue(isCompleted ? "Tamamlandı" : "Tamamlanmadı")
        .accessibilityHint(isCompleted ? "Tamamlanmadı olarak işaretler" : "Tamamlandı olarak işaretler")
    }

    private var timeOfDayTitle: LocalizedStringResource {
        switch routine.timeOfDay {
        case .morning: "Sabah"
        case .afternoon: "Öğleden sonra"
        case .evening: "Akşam"
        case .anytime: "Gün içinde"
        }
    }
}

private struct EmptyTodayCard: View {
    let onAddTask: () -> Void

    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.green)
                    .symbolEffect(.breathe)
                Text("Odak listen boş")
                    .font(AppTypography.title)
                Text("Bugün dinlenebilir veya İş Havuzu’ndan anlamlı bir sonraki adım seçebilirsin.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                Button("Bugüne İş Seç", systemImage: "plus", action: onAddTask)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity, minHeight: 260)
        }
    }
}

private struct CurrentTaskCard: View {
    let task: TaskItem
    let nextTaskTitle: String?
    let activeSession: FocusSession?
    let onStart: () -> Void
    let onPostpone: () -> Void
    let onSwitchTask: () -> Void
    let onAbandonTask: () -> Void

    var body: some View {
        AppCard(padding: AppSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack {
                    HStack(spacing: AppSpacing.xSmall) {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .symbolEffect(.pulse)
                        Text(task.status == .active ? "ODAK OTURUMU AKTİF" : "ŞİMDİ")
                            .font(AppTypography.overline)
                            .foregroundStyle(.tint)
                    }
                    Spacer()
                    if let start = task.scheduledStart, let end = task.scheduledEnd {
                        Label {
                            Text(
                                "\(start.formatted(.dateTime.hour().minute().locale(Locale(identifier: "tr_TR"))))–\(end.formatted(.dateTime.hour().minute().locale(Locale(identifier: "tr_TR"))))"
                            )
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Text(task.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)

                if let activeSession {
                    ActiveFocusTimingView(
                        session: activeSession,
                        onSwitchTask: nextTaskTitle == nil ? nil : onSwitchTask,
                        onAbandonTask: onAbandonTask
                    )
                }

                if let firstAction = task.firstAction {
                    HStack(spacing: AppSpacing.small) {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("İlk hareket")
                                .font(AppTypography.overline)
                                .foregroundStyle(.secondary)
                            Text(firstAction)
                                .font(.title3.weight(.medium))
                        }
                    }
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.accentColor.opacity(0.075), in: RoundedRectangle(cornerRadius: 13))
                } else {
                    Label("İşi başlat ve ilk küçük adımı belirle", systemImage: "lightbulb")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ViewThatFits {
                    HStack(spacing: AppSpacing.small) {
                        primaryButton
                        postponeButton
                    }

                    VStack(spacing: AppSpacing.small) {
                        primaryButton.frame(maxWidth: .infinity)
                        postponeButton.frame(maxWidth: .infinity)
                    }
                }

                if let nextTaskTitle {
                    Divider()
                    HStack(spacing: AppSpacing.small) {
                        Text("SONRA")
                            .font(AppTypography.overline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.tertiary)
                        Text(nextTaskTitle)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Image(systemName: "scope")
                .font(.system(size: 110))
                .foregroundStyle(Color.accentColor.opacity(0.035))
                .padding(AppSpacing.large)
                .accessibilityHidden(true)
        }
    }

    private var primaryButton: some View {
        Button(task.status == .active ? "Odağa Dön" : "Başla", systemImage: "scope", action: onStart)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut(.return, modifiers: .command)
    }

    private var postponeButton: some View {
        Button("Şimdi yapamıyorum", systemImage: "arrow.right.circle", action: onPostpone)
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(task.status == .active)
    }
}

private struct ActiveFocusTimingView: View {
    let session: FocusSession
    let onSwitchTask: (() -> Void)?
    let onAbandonTask: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let elapsed = max(session.elapsedTime(at: context.date), 0)
            let remaining = max(session.remainingTime(at: context.date), 0)
            let progress = session.plannedDuration > 0
                ? min(elapsed / session.plannedDuration, 1)
                : 0
            let canAbandon = session.plannedDuration > 0
                && elapsed / session.plannedDuration <= 0.1

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                HStack(spacing: AppSpacing.medium) {
                    FocusTimeMetric(
                        title: "Kalan süre",
                        value: Self.formatted(remaining),
                        systemImage: "timer",
                        color: .accentColor,
                        countsDown: true
                    )
                    FocusTimeMetric(
                        title: "Geçen süre",
                        value: Self.formatted(elapsed),
                        systemImage: "stopwatch",
                        color: .blue,
                        countsDown: false
                    )
                    FocusTimeMetric(
                        title: "Planlanan",
                        value: Self.formatted(session.plannedDuration),
                        systemImage: "hourglass",
                        color: .secondary,
                        countsDown: false
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    ProgressView(value: progress, total: 1)
                        .tint(progress >= 0.9 ? .orange : .accentColor)
                        .scaleEffect(y: 1.45)
                        .animation(.linear(duration: 1), value: progress)

                    HStack {
                        Text("%\(Int(progress * 100)) tamamlandı")
                            .contentTransition(.numericText())
                        Spacer()
                        if session.state == .paused {
                            Label("Duraklatıldı", systemImage: "pause.fill")
                                .foregroundStyle(.orange)
                        } else {
                            Label("Odak sürüyor", systemImage: "waveform.path")
                                .foregroundStyle(.green)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                }

                HStack(spacing: AppSpacing.small) {
                    if let onSwitchTask {
                        Button("Başka İşe Geç", systemImage: "arrow.triangle.2.circlepath", action: onSwitchTask)
                            .buttonStyle(.bordered)
                    }

                    if canAbandon {
                        Button("Şimdilik Geç", systemImage: "arrow.down.to.line", action: onAbandonTask)
                            .buttonStyle(.bordered)
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    }
                }
            }
            .padding(AppSpacing.medium)
            .background(Color.accentColor.opacity(0.065), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private static func formatted(_ interval: TimeInterval) -> String {
        let seconds = max(Int(interval), 0)
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

private struct FocusTimeMetric: View {
    let title: LocalizedStringKey
    let value: String
    let systemImage: String
    let color: Color
    let countsDown: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Label(title, systemImage: systemImage)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
                .contentTransition(.numericText(countsDown: countsDown))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TodayPlanCard: View {
    let tasks: [TaskItem]
    let currentTaskID: UUID
    let onAddTask: () -> Void
    let onRemoveTask: (TaskItem) -> Void

    var body: some View {
        AppCard {
            HStack(alignment: .top, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Bugünün planı",
                    subtitle: "\(tasks.count) iş seçildi. Odaktaki iş dışındakileri plandan çıkarabilirsin.",
                    systemImage: "list.bullet"
                )

                Button("Ekle", systemImage: "plus", action: onAddTask)
                    .buttonStyle(.bordered)
            }

            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TodayPlanRow(
                        task: task,
                        isCurrent: task.id == currentTaskID,
                        onRemove: { onRemoveTask(task) }
                    )

                    if task.id != tasks.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.top, AppSpacing.small)
        }
    }
}

private struct TodayPlanRow: View {
    let task: TaskItem
    let isCurrent: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: isCurrent ? "scope" : "circle")
                .foregroundStyle(isCurrent ? Color.accentColor : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(task.title)
                    .font(.body.weight(isCurrent ? .semibold : .regular))

                HStack(spacing: AppSpacing.small) {
                    if isCurrent {
                        Text("Sıradaki")
                            .foregroundStyle(Color.accentColor)
                    }

                    if let duration = task.estimatedDuration {
                        Text("\(Int(duration / 60)) dk")
                    }

                    if let start = task.scheduledStart {
                        Text(start, format: .dateTime.hour().minute())
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.small)

            Button("Plandan Çıkar", systemImage: "minus.circle", role: .destructive, action: onRemove)
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(task.status == .active)
                .help(task.status == .active ? "Odaktaki iş plandan çıkarılamaz" : "Bugünün planından çıkar")
        }
        .padding(.vertical, AppSpacing.small)
    }
}

private struct FocusTaskSwitcherSheet: View {
    let tasks: [TaskItem]
    let onSwitch: (TaskItem) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("Başka İşe Geç")
                        .font(AppTypography.title)
                    Text("Mevcut odak denemesi durdurulur; seçtiğin iş için yeni bir sayaç başlar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(AppSpacing.large)

            Divider()

            if tasks.isEmpty {
                ContentUnavailableView(
                    "Geçilebilecek başka iş yok",
                    systemImage: "checklist",
                    description: Text("Önce bugünün planına başka bir iş ekleyebilirsin.")
                )
                .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                List(tasks) { task in
                    HStack(spacing: AppSpacing.medium) {
                        Image(systemName: "scope")
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                            Text(task.title)
                                .font(.body.weight(.medium))
                            if let duration = task.estimatedDuration {
                                Text("\(Int(duration / 60)) dakika planlandı")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Button("Bu İşe Geç", systemImage: "arrow.right") {
                            onSwitch(task)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, AppSpacing.xSmall)
                }
                .listStyle(.inset)
            }

            Divider()

            HStack {
                Spacer()
                Button("Vazgeç", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(AppSpacing.medium)
            .background(.bar)
        }
        .frame(minWidth: 460, idealWidth: 560, maxWidth: 660, minHeight: 400, idealHeight: 480)
    }
}

private struct TodayTaskPickerSheet: View {
    let tasks: [TaskItem]
    let onAdd: (TaskItem) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var visibleTasks: [TaskItem] {
        guard !searchText.isEmpty else { return tasks }
        return tasks.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "calendar.badge.plus")
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("Bugüne İş Ekle")
                        .font(AppTypography.title)
                    Text("İş Havuzu’ndaki görevlerden birini bugünün sonuna ekle.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(AppSpacing.large)

            Divider()

            if tasks.isEmpty {
                ContentUnavailableView(
                    "İş Havuzu boş",
                    systemImage: "tray",
                    description: Text("Önce İş Havuzu’na yeni bir görev ekle.")
                )
                .frame(maxWidth: .infinity, minHeight: 280)
            } else {
                List(visibleTasks) { task in
                    TodayTaskPickerRow(task: task) {
                        onAdd(task)
                    }
                }
                .listStyle(.inset)
                .searchable(text: $searchText, prompt: "İş ara")
                .frame(minHeight: 280)
            }

            Divider()

            HStack {
                Spacer()
                Button("Bitti") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(AppSpacing.medium)
            .background(.bar)
        }
        .frame(minWidth: 440, idealWidth: 520, maxWidth: 620, minHeight: 420, idealHeight: 500)
    }
}

private struct TodayTaskPickerRow: View {
    let task: TaskItem
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: task.status == .stopped ? "pause.circle.fill" : "tray.fill")
                .foregroundStyle(task.status == .stopped ? .orange : .blue)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(task.title)
                    .lineLimit(2)

                if let duration = task.estimatedDuration {
                    Text("\(Int(duration / 60)) dakika")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button("Bugüne Ekle", systemImage: "plus", action: onAdd)
                .buttonStyle(.bordered)
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}
