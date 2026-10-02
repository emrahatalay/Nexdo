import SwiftData
import SwiftUI

struct RoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: RoutinesViewModel?
    @State private var showCreateSheet = false

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(SidebarSection.routines.title)
        .toolbar {
            ToolbarItem {
                Button {
                    showCreateSheet = true
                } label: {
                    Label("Yeni Rutin", systemImage: "plus")
                }
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

    @ViewBuilder
    private func content(_ viewModel: RoutinesViewModel) -> some View {
        if viewModel.allRoutines.isEmpty {
            ContentUnavailableView(
                "Henüz bir rutin yok.",
                systemImage: "repeat",
                description: Text("Düzenli tekrar eden alışkanlıklarını buraya ekle.")
            )
        } else {
            List {
                Section("Bugünkü Rutinler") {
                    if viewModel.todaysRoutines.isEmpty {
                        Text("Bugün için planlı rutin yok.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(viewModel.todaysRoutines) { routine in
                            RoutineRowView(
                                routine: routine,
                                isCompleted: viewModel.isCompletedToday(routine),
                                onToggle: { viewModel.toggleCompletion(for: routine) }
                            )
                        }
                    }
                }

                Section("Tüm Rutinler") {
                    ForEach(viewModel.allRoutines) { routine in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.title)
                                Text(recurrenceSummary(routine))
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Toggle(
                                "",
                                isOn: Binding(
                                    get: { routine.isActive },
                                    set: { viewModel.setActive(routine, isActive: $0) }
                                )
                            )
                            .labelsHidden()
                            .accessibilityLabel("\(routine.title) aktif")
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            viewModel.delete(viewModel.allRoutines[index])
                        }
                    }
                }
            }
            .listStyle(.inset)
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .contentMargins(.horizontal, AppSpacing.medium, for: .scrollContent)
        }
    }

    private func recurrenceSummary(_ routine: Routine) -> String {
        switch routine.recurrenceType {
        case .everyDay: "Her gün"
        case .weekdays: "Hafta içi"
        case .selectedWeekdays: "Seçili günler"
        case .weekly: "Haftalık"
        case .custom: "Özel"
        }
    }
}
