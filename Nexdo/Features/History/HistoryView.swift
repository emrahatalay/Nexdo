import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: HistoryViewModel?
    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilter = .all

    var body: some View {
        Group {
            if let viewModel {
                HistoryWorkspaceView(
                    viewModel: viewModel,
                    searchText: $searchText,
                    selectedFilter: $selectedFilter
                )
                .transition(.opacity)
            } else {
                ProgressView("Geçmiş hazırlanıyor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppBackground())
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel == nil)
        .navigationTitle(SidebarSection.history.title)
        .task {
            if viewModel == nil {
                viewModel = HistoryViewModel(modelContext: modelContext)
            } else {
                viewModel?.refresh()
            }
        }
        .alert(
            "İş geri alınamadı",
            isPresented: Binding(
                get: { viewModel?.errorMessage != nil },
                set: { if !$0 { viewModel?.errorMessage = nil } }
            )
        ) {
            Button("Tamam") { viewModel?.errorMessage = nil }
        } message: {
            Text(viewModel?.errorMessage ?? "")
        }
    }
}

private struct HistoryWorkspaceView: View {
    let viewModel: HistoryViewModel
    @Binding var searchText: String
    @Binding var selectedFilter: HistoryFilter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var completedCount: Int {
        viewModel.days.reduce(0) { $0 + $1.completedSessions.count }
    }

    private var stoppedCount: Int {
        viewModel.days.reduce(0) { $0 + $1.stoppedSessions.count }
    }

    private var focusMinutes: Int {
        viewModel.days.reduce(0) { $0 + $1.totalActualMinutes }
    }

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                HistoryHeroView(
                    dayCount: viewModel.days.count,
                    completedCount: completedCount,
                    stoppedCount: stoppedCount,
                    focusMinutes: focusMinutes
                )

                if viewModel.days.isEmpty {
                    HistoryEmptyView()
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: AppSpacing.large) {
                            HistoryTrendCard(days: viewModel.days)
                                .frame(maxWidth: .infinity, alignment: .top)
                            HistoryInsightCard(insight: viewModel.estimationInsight)
                                .frame(width: 330, alignment: .top)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.large) {
                            HistoryTrendCard(days: viewModel.days)
                            HistoryInsightCard(insight: viewModel.estimationInsight)
                        }
                    }

                    HistoryRecordsCard(
                        days: viewModel.days,
                        searchText: $searchText,
                        selectedFilter: $selectedFilter,
                        onRestore: viewModel.restoreToInbox
                    )
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: viewModel.days)
    }
}

private struct HistoryHeroView: View {
    let dayCount: Int
    let completedCount: Int
    let stoppedCount: Int
    let focusMinutes: Int

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
                colors: [Color.indigo.opacity(0.16), Color.accentColor.opacity(0.035)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 86))
                .foregroundStyle(Color.indigo.opacity(0.055))
                .padding(AppSpacing.medium)
                .accessibilityHidden(true)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("SON 14 GÜN")
                .font(AppTypography.overline)
                .foregroundStyle(.indigo)
            Text("İlerlemene geriye dönüp bak")
                .font(AppTypography.pageTitle)
            Text("Tamamladıklarını gör, süre tahminlerini geliştir ve gerekirse bir işi yeniden havuza al.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var metrics: some View {
        HStack(spacing: AppSpacing.small) {
            HistoryMetric(value: completedCount, label: "Tamamlanan", color: .green)
            HistoryMetric(value: focusMinutes, label: "Odak dk", color: .indigo)
            HistoryMetric(value: stoppedCount, label: "Durdurulan", color: .orange)
        }
    }
}

private struct HistoryMetric: View {
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

private struct HistoryTrendCard: View {
    let days: [HistoryViewModel.DaySummary]

    private var chartDays: [HistoryViewModel.DaySummary] {
        Array(days.prefix(7).reversed())
    }

    private var maximumMinutes: Int {
        max(chartDays.map(\.totalActualMinutes).max() ?? 0, 1)
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                AppSectionHeader(
                    "Odak ritmi",
                    subtitle: "Son günlerde gerçekleştirdiğin odak süresi.",
                    systemImage: "chart.bar.fill"
                )

                HStack(alignment: .bottom, spacing: AppSpacing.small) {
                    ForEach(chartDays) { day in
                        HistoryDayBar(day: day, maximumMinutes: maximumMinutes)
                    }
                }
                .frame(height: 150)
            }
        }
    }
}

private struct HistoryDayBar: View {
    let day: HistoryViewModel.DaySummary
    let maximumMinutes: Int

    var body: some View {
        VStack(spacing: AppSpacing.xSmall) {
            Text("\(day.totalActualMinutes)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            GeometryReader { proxy in
                VStack {
                    Spacer(minLength: 0)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            Calendar.current.isDateInToday(day.date)
                                ? Color.accentColor
                                : Color.indigo.opacity(0.52)
                        )
                        .frame(height: max(8, proxy.size.height * Double(day.totalActualMinutes) / Double(maximumMinutes)))
                }
            }
            Text(day.date, format: .dateTime.weekday(.narrow))
                .font(AppTypography.caption.weight(.semibold))
                .foregroundStyle(Calendar.current.isDateInToday(day.date) ? Color.accentColor : .secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(day.date.formatted(date: .abbreviated, time: .omitted)), \(day.totalActualMinutes) dakika odak"))
    }
}

private struct HistoryInsightCard: View {
    let insight: EstimationInsight

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Tahmin içgörüsü",
                    subtitle: "Planladığın süre ile gerçekleşen süre arasındaki ilişki.",
                    systemImage: "scope"
                )

                if let summary = insight.summary {
                    Image(systemName: insight.averageRatio <= 1 ? "checkmark.seal.fill" : "gauge.with.dots.needle.67percent")
                        .font(.largeTitle)
                        .foregroundStyle(insight.averageRatio <= 1 ? Color.green : Color.orange)
                        .symbolEffect(.bounce, value: insight.sampleSize)
                    Text(summary)
                        .font(.body.weight(.medium))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(insight.sampleSize) tamamlanmış iş üzerinden hesaplandı.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Birkaç işi tamamladığında süre tahminlerin hakkında burada bir içgörü göreceksin.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}

private struct HistoryRecordsCard: View {
    let days: [HistoryViewModel.DaySummary]
    @Binding var searchText: String
    @Binding var selectedFilter: HistoryFilter
    let onRestore: (HistoryViewModel.SessionRecord) -> Void

    private var visibleDays: [HistoryViewModel.DaySummary] {
        days.compactMap { day in
            let completed = day.completedSessions.filter(isVisible)
            let stopped = day.stoppedSessions.filter(isVisible)
            guard !completed.isEmpty || !stopped.isEmpty else { return nil }
            return HistoryViewModel.DaySummary(
                date: day.date,
                completedSessions: completed,
                stoppedSessions: stopped,
                postponementCount: day.postponementCount,
                totalActualMinutes: day.totalActualMinutes,
                routineExpected: day.routineExpected,
                routineCompleted: day.routineCompleted
            )
        }
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Çalışma kayıtları",
                    subtitle: "Bir işi yeniden ele almak istersen İş Havuzu’na geri gönderebilirsin.",
                    systemImage: "clock.arrow.circlepath"
                )

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.medium) {
                        HistorySearchField(searchText: $searchText)
                        HistoryFilterPicker(selection: $selectedFilter)
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        HistorySearchField(searchText: $searchText)
                        HistoryFilterPicker(selection: $selectedFilter)
                    }
                }

                if visibleDays.isEmpty {
                    ContentUnavailableView(
                        "Kayıt bulunamadı",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Arama metnini veya seçili filtreyi değiştirebilirsin.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.large) {
                        ForEach(visibleDays) { day in
                            HistoryDaySection(day: day, onRestore: onRestore)
                        }
                    }
                }
            }
        }
    }

    private func isVisible(_ record: HistoryViewModel.SessionRecord) -> Bool {
        selectedFilter.includes(record)
            && (searchText.isEmpty || record.taskTitle.localizedStandardContains(searchText))
    }
}

private struct HistoryDaySection: View {
    let day: HistoryViewModel.DaySummary
    let onRestore: (HistoryViewModel.SessionRecord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(AppTypography.sectionTitle)
                    Text("\(day.totalActualMinutes) dk odak • \(day.completedSessions.count) tamamlanan")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if day.routineExpected > 0 {
                    Label("\(day.routineCompleted)/\(day.routineExpected)", systemImage: "repeat")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.bottom, AppSpacing.xSmall)

            ForEach(day.completedSessions) { record in
                HistorySessionRow(record: record, onRestore: { onRestore(record) })
            }
            ForEach(day.stoppedSessions) { record in
                HistorySessionRow(record: record, onRestore: { onRestore(record) })
            }
        }
        .padding(AppSpacing.medium)
        .background(Color.secondary.opacity(0.045), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct HistorySessionRow: View {
    let record: HistoryViewModel.SessionRecord
    let onRestore: () -> Void

    private var isStopped: Bool {
        record.state == .stopped
    }

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: isStopped ? "pause.fill" : "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(isStopped ? Color.orange : Color.green, in: Circle())

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text(record.taskTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                HStack(spacing: AppSpacing.medium) {
                    Label("\(record.estimatedMinutes) dk plan", systemImage: "calendar")
                    Label("\(record.actualMinutes) dk gerçek", systemImage: "stopwatch")
                    AppStatusBadge(title: isStopped ? "DURDURULDU" : "TAMAMLANDI", color: isStopped ? .orange : .green)
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.small)

            if record.canRestore {
                Button("İş Havuzu’na Al", systemImage: "arrow.uturn.backward", action: onRestore)
                    .buttonStyle(.bordered)
                    .help("Geçmiş kaydını koruyarak işi yeniden İş Havuzu’na al")
            } else {
                Label("Havuzda", systemImage: "tray.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}

private struct HistorySearchField: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Geçmişte ara", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button("Temizle", systemImage: "xmark.circle.fill") { searchText = "" }
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

private struct HistoryFilterPicker: View {
    @Binding var selection: HistoryFilter

    var body: some View {
        Picker("Filtre", selection: $selection) {
            ForEach(HistoryFilter.allCases) { filter in
                Label(filter.title, systemImage: filter.systemImage).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct HistoryEmptyView: View {
    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)
                    .symbolEffect(.pulse)
                Text("Hikâyen burada başlayacak")
                    .font(AppTypography.title)
                Text("Tamamladığın ve durdurduğun odak oturumları burada gün gün birikecek.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxLarge)
        }
    }
}

private enum HistoryFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case stopped

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .all: "Tümü"
        case .completed: "Tamamlanan"
        case .stopped: "Durdurulan"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "clock.arrow.circlepath"
        case .completed: "checkmark.circle"
        case .stopped: "pause.circle"
        }
    }

    func includes(_ record: HistoryViewModel.SessionRecord) -> Bool {
        switch self {
        case .all: true
        case .completed: record.state == .completed
        case .stopped: record.state == .stopped
        }
    }
}
