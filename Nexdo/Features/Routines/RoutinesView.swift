import SwiftData
import SwiftUI

struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var viewModel: RoutinesViewModel?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if let viewModel {
                RoutinesWorkspaceView(
                    viewModel: viewModel,
                    onCreate: { showCreateSheet = true }
                )
                .transition(.opacity)
            } else {
                ProgressView("Rutinler hazırlanıyor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppBackground())
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: viewModel == nil)
        .navigationTitle(SidebarSection.routines.title)
        .toolbar {
            ToolbarItem {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("Yeni Rutin", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
        .task {
            if viewModel == nil {
                viewModel = RoutinesViewModel(modelContext: modelContext)
            } else {
                viewModel?.refresh()
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            RoutineFormSheet { title, minutes, timeOfDay, recurrence, mask in
                viewModel?.createRoutine(
                    title: title,
                    estimatedMinutes: minutes,
                    timeOfDay: timeOfDay,
                    recurrenceType: recurrence,
                    selectedWeekdaysMask: mask
                )
                showCreateSheet = false
            }
        }
    }
}

private struct RoutinesWorkspaceView: View {
    let viewModel: RoutinesViewModel
    let onCreate: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                RoutinesHeroView(
                    activeCount: viewModel.allRoutines.filter(\.isActive).count,
                    todayCount: viewModel.todaysRoutines.count,
                    completedCount: viewModel.todaysRoutines.filter(viewModel.isCompletedToday).count,
                    todayMinutes: viewModel.todaysRoutines.reduce(0) { $0 + Int($1.estimatedDuration / 60) },
                    onCreate: onCreate
                )

                if viewModel.allRoutines.isEmpty {
                    RoutinesEmptyView(onCreate: onCreate)
                } else {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: AppSpacing.large) {
                            TodayRoutinesCard(viewModel: viewModel)
                                .frame(maxWidth: .infinity, alignment: .top)
                            RoutineRhythmCard(routines: viewModel.allRoutines)
                                .frame(width: 310, alignment: .top)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.large) {
                            TodayRoutinesCard(viewModel: viewModel)
                            RoutineRhythmCard(routines: viewModel.allRoutines)
                        }
                    }

                    RoutineLibraryCard(viewModel: viewModel)
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy(duration: 0.35), value: viewModel.allRoutines.count)
        .animation(reduceMotion ? nil : .snappy(duration: 0.3), value: viewModel.completedRoutineIDs.count)
    }
}

private struct RoutinesHeroView: View {
    let activeCount: Int
    let todayCount: Int
    let completedCount: Int
    let todayMinutes: Int
    let onCreate: () -> Void

    private var progress: Double {
        guard todayCount > 0 else { return 0 }
        return Double(completedCount) / Double(todayCount)
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: AppSpacing.xLarge) {
                title
                Spacer(minLength: AppSpacing.medium)
                progressSummary
                Button("Rutin Ekle", systemImage: "plus", action: onCreate)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }

            VStack(alignment: .leading, spacing: AppSpacing.large) {
                title
                progressSummary
                Button("Rutin Ekle", systemImage: "plus", action: onCreate)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
        .padding(AppSpacing.large)
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.15), Color.accentColor.opacity(0.045)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
        )
        .overlay(alignment: .topTrailing) {
            Image(systemName: "repeat.circle.fill")
                .font(.system(size: 86))
                .foregroundStyle(Color.green.opacity(0.055))
                .padding(AppSpacing.medium)
                .accessibilityHidden(true)
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text("RİTİMLERİNİ KORU")
                .font(AppTypography.overline)
                .foregroundStyle(.green)
            Text("Küçük adımlar, kalıcı düzen")
                .font(AppTypography.pageTitle)
            Text("Tekrarlanan işleri zihninden çıkar; doğru günde, doğru zamanda karşına gelsin.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var progressSummary: some View {
        HStack(spacing: AppSpacing.medium) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 7)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(completedCount)/\(todayCount)")
                    .font(.headline.monospacedDigit())
                    .contentTransition(.numericText())
            }
            .frame(width: 68, height: 68)

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text("Bugünkü ilerleme")
                    .font(.body.weight(.semibold))
                Text("\(activeCount) aktif rutin • \(todayMinutes) dk bugün")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TodayRoutinesCard: View {
    let viewModel: RoutinesViewModel

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Bugünün rutinleri",
                    subtitle: "Tamamladıkça işaretle; ilerlemen günlük olarak saklanır.",
                    systemImage: "checkmark.circle"
                )

                if viewModel.todaysRoutines.isEmpty {
                    VStack(spacing: AppSpacing.small) {
                        Image(systemName: "cup.and.saucer")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("Bugün için planlı rutin yok")
                            .font(AppTypography.sectionTitle)
                        Text("Bugünü boş bırakabilir veya kütüphanenden yeni bir ritim oluşturabilirsin.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.xLarge)
                } else {
                    ForEach(viewModel.todaysRoutines) { routine in
                        RoutineRowView(
                            routine: routine,
                            isCompleted: viewModel.isCompletedToday(routine),
                            onToggle: { viewModel.toggleCompletion(for: routine) }
                        )
                        if routine.id != viewModel.todaysRoutines.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private struct RoutineRhythmCard: View {
    let routines: [Routine]

    private var activeRoutines: [Routine] {
        routines.filter(\.isActive)
    }

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Haftalık ritim",
                    subtitle: "Aktif rutinlerinin haftaya dağılımı.",
                    systemImage: "calendar"
                )

                ForEach(RoutineWeekdayDisplay.allCases) { day in
                    RoutineDayLoadRow(
                        title: day.shortTitle,
                        count: activeRoutines.filter { day.includes($0) }.count,
                        minutes: activeRoutines.filter { day.includes($0) }.reduce(0) { $0 + Int($1.estimatedDuration / 60) },
                        isToday: day.isToday
                    )
                }
            }
        }
    }
}

private struct RoutineDayLoadRow: View {
    let title: LocalizedStringKey
    let count: Int
    let minutes: Int
    let isToday: Bool

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isToday ? .white : .secondary)
                .frame(width: 30, height: 30)
                .background(isToday ? Color.accentColor : Color.secondary.opacity(0.09), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(count == 0 ? Color.secondary.opacity(0.1) : Color.green.opacity(0.75))
                        .frame(width: count == 0 ? 8 : max(24, proxy.size.width * min(Double(count) / 5, 1)))
                }
                .frame(height: 6)
                Text(count == 0 ? "Dinlenme" : "\(count) rutin • \(minutes) dk")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct RoutineLibraryCard: View {
    let viewModel: RoutinesViewModel

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                AppSectionHeader(
                    "Rutin kütüphanesi",
                    subtitle: "Programını gözden geçir, geçici olarak duraklat veya artık gerekli olmayan rutinleri kaldır.",
                    systemImage: "books.vertical"
                )

                ForEach(viewModel.allRoutines) { routine in
                    RoutineLibraryRow(
                        routine: routine,
                        onActiveChange: { viewModel.setActive(routine, isActive: $0) },
                        onDelete: { viewModel.delete(routine) }
                    )
                    if routine.id != viewModel.allRoutines.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct RoutineLibraryRow: View {
    let routine: Routine
    let onActiveChange: (Bool) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.medium) {
            Image(systemName: routine.timeOfDay.icon)
                .font(.title3)
                .foregroundStyle(routine.isActive ? Color.accentColor : .secondary)
                .frame(width: 40, height: 40)
                .background(
                    (routine.isActive ? Color.accentColor : Color.secondary).opacity(0.1),
                    in: RoundedRectangle(cornerRadius: 11)
                )

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                HStack(spacing: AppSpacing.small) {
                    Text(routine.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(routine.isActive ? .primary : .secondary)
                    if !routine.isActive {
                        AppStatusBadge(title: "DURAKLATILDI", color: .secondary)
                    }
                }
                HStack(spacing: AppSpacing.medium) {
                    Label(routine.recurrenceSummary, systemImage: "repeat")
                    Label("\(Int(routine.estimatedDuration / 60)) dk", systemImage: "clock")
                    Label(routine.timeOfDay.title, systemImage: routine.timeOfDay.icon)
                }
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.medium)

            Toggle(
                "Aktif",
                isOn: Binding(get: { routine.isActive }, set: onActiveChange)
            )
            .labelsHidden()
            .accessibilityLabel("\(routine.title) aktif")

            Menu {
                Button("Rutini Sil", systemImage: "trash", role: .destructive, action: onDelete)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Rutin seçenekleri")
        }
        .padding(.vertical, AppSpacing.small)
        .opacity(routine.isActive ? 1 : 0.72)
    }
}

private struct RoutinesEmptyView: View {
    let onCreate: () -> Void

    var body: some View {
        AppCard {
            VStack(spacing: AppSpacing.medium) {
                Image(systemName: "repeat.circle")
                    .font(.system(size: 46))
                    .foregroundStyle(.green)
                    .symbolEffect(.pulse)
                Text("İlk ritmini oluştur")
                    .font(AppTypography.title)
                Text("Her gün tekrar düşündüğün bir işi rutine dönüştür. Nexdo doğru gün geldiğinde onu planına eklesin.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
                Button("İlk Rutini Ekle", systemImage: "plus", action: onCreate)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.xxLarge)
        }
    }
}

private enum RoutineWeekdayDisplay: Int, CaseIterable, Identifiable {
    case monday = 2, tuesday, wednesday, thursday, friday, saturday, sunday = 1

    var id: Int { rawValue }

    var shortTitle: LocalizedStringKey {
        switch self {
        case .monday: "Pt"
        case .tuesday: "Sa"
        case .wednesday: "Ça"
        case .thursday: "Pe"
        case .friday: "Cu"
        case .saturday: "Ct"
        case .sunday: "Pz"
        }
    }

    var isToday: Bool {
        Calendar.current.component(.weekday, from: .now) == rawValue
    }

    func includes(_ routine: Routine) -> Bool {
        switch routine.recurrenceType {
        case .everyDay, .custom:
            true
        case .weekdays:
            self != .saturday && self != .sunday
        case .selectedWeekdays, .weekly:
            routine.selectedWeekdaysMask & weekday.rawValue != 0
        }
    }

    private var weekday: Weekday {
        switch self {
        case .monday: .monday
        case .tuesday: .tuesday
        case .wednesday: .wednesday
        case .thursday: .thursday
        case .friday: .friday
        case .saturday: .saturday
        case .sunday: .sunday
        }
    }
}

private extension Routine {
    var recurrenceSummary: String {
        switch recurrenceType {
        case .everyDay: "Her gün"
        case .weekdays: "Hafta içi"
        case .selectedWeekdays: "Seçili günler"
        case .weekly: "Haftalık"
        case .custom: "Özel program"
        }
    }
}

private extension RoutineTimeOfDay {
    var title: String {
        switch self {
        case .morning: "Sabah"
        case .afternoon: "Öğleden sonra"
        case .evening: "Akşam"
        case .anytime: "Gün içinde"
        }
    }

    var icon: String {
        switch self {
        case .morning: "sunrise.fill"
        case .afternoon: "sun.max.fill"
        case .evening: "sunset.fill"
        case .anytime: "clock.fill"
        }
    }
}
