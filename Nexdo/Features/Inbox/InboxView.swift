import SwiftData
import SwiftUI

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var newTaskTitle = ""
    @State private var searchText = ""
    @State private var selectedFilter: InboxFilter = .all
    @State private var errorMessage: String?
    @FocusState private var isCaptureFieldFocused: Bool

    private var inboxTasks: [TaskItem] {
        allTasks.filter { $0.status == .inbox || $0.status == .stopped }
    }

    private var visibleTasks: [TaskItem] {
        inboxTasks.filter { task in
            selectedFilter.includes(task)
                && (searchText.isEmpty || task.title.localizedStandardContains(searchText))
        }
    }

    private var repository: TaskRepository {
        SwiftDataTaskRepository(modelContext: modelContext)
    }

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                InboxHero(
                    taskCount: inboxTasks.count,
                    stoppedCount: inboxTasks.filter { $0.status == .stopped }.count,
                    capturedTodayCount: inboxTasks.filter { Calendar.current.isDateInToday($0.createdAt) }.count
                )

                CaptureCard(
                    title: $newTaskTitle,
                    isFocused: $isCaptureFieldFocused,
                    capturedCount: inboxTasks.count,
                    onCapture: capture
                )

                InboxWorkflowHint()

                InboxTaskSection(
                    tasks: visibleTasks,
                    totalCount: inboxTasks.count,
                    searchText: $searchText,
                    selectedFilter: $selectedFilter,
                    onDelete: delete
                )
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: inboxTasks.count)
        .navigationTitle(SidebarSection.inbox.title)
        .toolbar {
            ToolbarItem {
                Button {
                    isCaptureFieldFocused = true
                } label: {
                    Label("Hızlı Ekle", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
                .help("Yeni iş ekleme alanına geç")
            }
        }
        .alert(
            "Kaydedilemedi",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("Tamam") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func capture() {
        do {
            if try repository.capture(title: newTaskTitle) {
                newTaskTitle = ""
                isCaptureFieldFocused = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(_ task: TaskItem) {
        do {
            try repository.delete(task)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct InboxHero: View {
    let taskCount: Int
    let stoppedCount: Int
    let capturedTodayCount: Int

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppSpacing.xLarge) {
                title
                Spacer(minLength: AppSpacing.medium)
                metrics
            }

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                title
                metrics
            }
        }
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.16), Color.accentColor.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "tray.full.fill")
                .font(.system(size: 82))
                .foregroundStyle(Color.blue.opacity(0.055))
                .padding(AppSpacing.medium)
                .accessibilityHidden(true)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("ZİHNİNİ BOŞALT")
                .font(AppTypography.overline)
                .foregroundStyle(.blue)
            Text("Aklından çıkar, sisteme bırak")
                .font(AppTypography.pageTitle)
            Text("Gelen işleri hızla yakala. Öncelik ve zaman kararını akşam planında ver.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metrics: some View {
        HStack(spacing: AppSpacing.small) {
            InboxMetric(value: taskCount, label: "Bekleyen", color: .blue)
            InboxMetric(value: capturedTodayCount, label: "Bugün gelen", color: .green)
            InboxMetric(value: stoppedCount, label: "Durdurulan", color: .orange)
        }
    }
}

private struct InboxMetric: View {
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
        .frame(minWidth: 78)
        .padding(.vertical, AppSpacing.small)
        .background(.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct CaptureCard: View {
    @Binding var title: String
    let isFocused: FocusState<Bool>.Binding
    let capturedCount: Int
    let onCapture: () -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Hızlı yakala",
                    subtitle: "Sadece yapılacak işi yaz. Süre ve öncelik ayrıntılarını daha sonra netleştirebilirsin.",
                    systemImage: "bolt.fill"
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.medium) {
                        CaptureTextField(title: $title, isFocused: isFocused, onSubmit: onCapture)
                        CaptureButton(title: title, onCapture: onCapture)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        CaptureTextField(title: $title, isFocused: isFocused, onSubmit: onCapture)
                        CaptureButton(title: title, onCapture: onCapture)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }

                Label("Return ile kaydet • ⌘N ile bu alana dön", systemImage: "keyboard")
                    .font(AppTypography.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .symbolEffect(.bounce, value: capturedCount)
    }
}

private struct CaptureTextField: View {
    @Binding var title: String
    let isFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)

            TextField("Örn. Teklif dosyasını Ayşe'ye gönder", text: $title)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused(isFocused)
                .onSubmit(onSubmit)
                .accessibilityLabel("Yeni iş ekle")
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused.wrappedValue ? Color.accentColor.opacity(0.7) : Color.secondary.opacity(0.12))
        }
    }
}

private struct CaptureButton: View {
    let title: String
    let onCapture: () -> Void

    var body: some View {
        Button("Havuza Ekle", systemImage: "arrow.down.to.line", action: onCapture)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

private struct InboxWorkflowHint: View {
    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            InboxWorkflowStep(number: 1, title: "Yakala", subtitle: "Aklındaki işi yaz", color: .blue)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            InboxWorkflowStep(number: 2, title: "Değerlendir", subtitle: "Akşam önem ve aciliyeti seç", color: .orange)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
            InboxWorkflowStep(number: 3, title: "Planla", subtitle: "Süre ve ilk hareketi belirle", color: .green)
        }
        .padding(.horizontal, AppSpacing.medium)
    }
}

private struct InboxWorkflowStep: View {
    let number: Int
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let color: Color

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(number, format: .number)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 25, height: 25)
                .background(color, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(AppTypography.caption.weight(.semibold))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InboxTaskSection: View {
    let tasks: [TaskItem]
    let totalCount: Int
    @Binding var searchText: String
    @Binding var selectedFilter: InboxFilter
    let onDelete: (TaskItem) -> Void

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Bekleyen işler",
                    subtitle: "Burada yalnızca yakala ve gözden geçir; planlama kararlarını Akşam Planı'nda ver.",
                    systemImage: "list.bullet.rectangle"
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.medium) {
                        InboxSearchField(searchText: $searchText)
                        InboxFilterPicker(selection: $selectedFilter)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        InboxSearchField(searchText: $searchText)
                        InboxFilterPicker(selection: $selectedFilter)
                    }
                }

                if tasks.isEmpty {
                    InboxEmptyState(isFiltered: totalCount > 0, clearFilters: clearFilters)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(tasks) { task in
                            InboxTaskRow(task: task, onDelete: { onDelete(task) })
                            if task.id != tasks.last?.id {
                                Divider()
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
        }
    }

    private func clearFilters() {
        searchText = ""
        selectedFilter = .all
    }
}

private struct InboxSearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("İşlerde ara", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button("Temizle", systemImage: "xmark.circle.fill") {
                    searchText = ""
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xSmall)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
        .frame(maxWidth: 320)
    }
}

private struct InboxFilterPicker: View {
    @Binding var selection: InboxFilter

    var body: some View {
        Picker("Filtre", selection: $selection) {
            ForEach(InboxFilter.allCases) { filter in
                Label(filter.title, systemImage: filter.systemImage)
                    .tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct InboxEmptyState: View {
    let isFiltered: Bool
    let clearFilters: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: isFiltered ? "line.3.horizontal.decrease.circle" : "tray")
                .font(.largeTitle)
                .foregroundStyle(isFiltered ? Color.accentColor : .green)
            Text(isFiltered ? "Bu filtrede iş bulunamadı" : "İş havuzu tertemiz")
                .font(AppTypography.title)
            Text(isFiltered ? "Arama metnini veya seçili filtreyi değiştirebilirsin." : "Yeni bir iş geldiğinde yukarıdaki alana bırak; geri kalanını akşam planında çözersin.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if isFiltered {
                Button("Filtreleri Temizle", action: clearFilters)
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxLarge)
    }
}

private struct InboxTaskRow: View {
    let task: TaskItem
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.medium) {
            Image(systemName: task.status == .stopped ? "pause.fill" : task.source.icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(task.status == .stopped ? .orange : .blue)
                .frame(width: 36, height: 36)
                .background(
                    (task.status == .stopped ? Color.orange : Color.blue).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 10)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(spacing: AppSpacing.small) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)
                    if task.status == .stopped {
                        AppStatusBadge(title: "DURDURULDU", color: .orange)
                    }
                }

                HStack(spacing: AppSpacing.medium) {
                    Label(task.source.title, systemImage: task.source.icon)
                    Label {
                        Text(task.createdAt, format: .relative(presentation: .named))
                    } icon: {
                        Image(systemName: "clock")
                    }
                    if let projectName = task.project?.name {
                        Label(projectName, systemImage: "folder")
                    }
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.small)

            Menu {
                Button("Sil", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("İş seçenekleri")
            .accessibilityLabel("\(task.title) seçenekleri")
        }
        .padding(.vertical, AppSpacing.small)
    }
}

private enum InboxFilter: String, CaseIterable, Identifiable {
    case all
    case new
    case stopped

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .all: "Tümü"
        case .new: "Yeni"
        case .stopped: "Durdurulan"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "tray.full"
        case .new: "sparkles"
        case .stopped: "pause.circle"
        }
    }

    func includes(_ task: TaskItem) -> Bool {
        switch self {
        case .all: true
        case .new: task.status == .inbox
        case .stopped: task.status == .stopped
        }
    }
}

private extension TaskSource {
    var title: String {
        switch self {
        case .manual: "Elle eklendi"
        case .quickCapture: "Hızlı yakalama"
        case .recurring: "Rutinden geldi"
        case .imported: "İçe aktarıldı"
        }
    }

    var icon: String {
        switch self {
        case .manual: "square.and.pencil"
        case .quickCapture: "bolt.fill"
        case .recurring: "repeat"
        case .imported: "square.and.arrow.down"
        }
    }
}
