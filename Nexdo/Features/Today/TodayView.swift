import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: TodayViewModel?
    @State private var showPostponeSheet = false
    @State private var showTaskPicker = false
    @State private var taskToPostpone: TaskItem?

    var body: some View {
        Group {
            if let viewModel {
                TodayContent(
                    tasks: viewModel.todayTasks,
                    currentTask: viewModel.currentTask,
                    routines: viewModel.todayRoutines,
                    completedRoutineIDs: viewModel.completedRoutineIDs,
                    onStart: start,
                    onPostpone: { task in
                        taskToPostpone = task
                        showPostponeSheet = true
                    },
                    onAddTask: { showTaskPicker = true },
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
}

private struct TodayContent: View {
    let tasks: [TaskItem]
    let currentTask: TaskItem?
    let routines: [Routine]
    let completedRoutineIDs: Set<UUID>
    let onStart: (TaskItem) -> Void
    let onPostpone: (TaskItem) -> Void
    let onAddTask: () -> Void
    let onRemoveTask: (TaskItem) -> Void
    let onToggleRoutine: (Routine) -> Void

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                TodayHeader(onAddTask: onAddTask)

                if let currentTask {
                    CurrentTaskCard(
                        task: currentTask,
                        onStart: { onStart(currentTask) },
                        onPostpone: { onPostpone(currentTask) }
                    )

                } else {
                    EmptyTodayCard(onAddTask: onAddTask)
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

private struct TodayHeader: View {
    let onAddTask: () -> Void

    var body: some View {
        ViewThatFits {
            HStack(alignment: .bottom, spacing: AppSpacing.medium) {
                title
                Spacer(minLength: AppSpacing.medium)
                addButton
            }

            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                title
                addButton
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.accentColor)
            Text("Bugünün odağı")
                .font(AppTypography.pageTitle)
            Text("Planını gün içinde değişen önceliklere göre düzenleyebilirsin.")
                .foregroundStyle(.secondary)
        }
    }

    private var addButton: some View {
        Button("Bugüne İş Ekle", systemImage: "plus", action: onAddTask)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

private struct EmptyTodayCard: View {
    let onAddTask: () -> Void

    var body: some View {
        AppCard {
            ContentUnavailableView {
                Label("Bugün için iş seçilmedi", systemImage: "calendar.badge.plus")
            } description: {
                Text("İş Havuzu’ndan bir görev seçerek hemen bugünün planına ekleyebilirsin.")
            } actions: {
                Button("İş Seç", systemImage: "plus", action: onAddTask)
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, minHeight: 220)
        }
    }
}

private struct CurrentTaskCard: View {
    let task: TaskItem
    let onStart: () -> Void
    let onPostpone: () -> Void

    var body: some View {
        AppCard(padding: AppSpacing.xLarge) {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HStack {
                    AppStatusBadge(title: "Şimdi", color: .accentColor)
                    Spacer()
                    if let start = task.scheduledStart, let end = task.scheduledEnd {
                        Label {
                            Text("\(start.formatted(date: .omitted, time: .shortened))–\(end.formatted(date: .omitted, time: .shortened))")
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

                if let firstAction = task.firstAction {
                    Label(firstAction, systemImage: "arrow.forward.circle.fill")
                        .font(.title3)
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
            }
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
