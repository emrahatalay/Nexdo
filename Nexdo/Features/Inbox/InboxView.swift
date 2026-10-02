import SwiftData
import SwiftUI

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var newTaskTitle = ""
    @State private var errorMessage: String?
    @FocusState private var isCaptureFieldFocused: Bool

    private var inboxTasks: [TaskItem] {
        allTasks.filter { $0.status == .inbox || $0.status == .stopped }
    }

    private var repository: TaskRepository {
        SwiftDataTaskRepository(modelContext: modelContext)
    }

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: AppSpacing.large) {
                InboxHero(taskCount: inboxTasks.count)
                CaptureCard(
                    title: $newTaskTitle,
                    isFocused: $isCaptureFieldFocused,
                    onCapture: capture
                )

                if inboxTasks.isEmpty {
                    AppCard {
                        ContentUnavailableView(
                            "Her şey işlendi",
                            systemImage: "tray",
                            description: Text("Yeni bir iş geldiğinde onu yukarıdaki alana bırak.")
                        )
                        .frame(maxWidth: .infinity, minHeight: 220)
                    }
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        AppSectionHeader(
                            "Bekleyen işler",
                            subtitle: "Planlarken önem ve aciliyetine göre değerlendir.",
                            systemImage: "list.bullet"
                        )

                        LazyVStack(spacing: AppSpacing.small) {
                            ForEach(inboxTasks) { task in
                                InboxTaskRow(task: task) {
                                    delete(task)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(SidebarSection.inbox.title)
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

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Aklından çıkar, sisteme bırak")
                    .font(AppTypography.pageTitle)
                Text("Gelen işleri hızla yakala; ne zaman yapılacağına planlama sırasında karar ver.")
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: AppSpacing.medium)

            AppStatusBadge(
                title: taskCount == 1 ? "1 iş" : "\(taskCount) iş",
                color: .blue
            )
        }
    }
}

private struct CaptureCard: View {
    @Binding var title: String
    let isFocused: FocusState<Bool>.Binding
    let onCapture: () -> Void

    var body: some View {
        AppCard {
            ViewThatFits {
                HStack(spacing: AppSpacing.medium) {
                    captureField
                    addButton
                }

                VStack(alignment: .leading, spacing: AppSpacing.small) {
                    captureField
                    addButton
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var captureField: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            TextField("Ne yapman gerekiyor?", text: $title)
                .textFieldStyle(.plain)
                .font(.title3)
                .focused(isFocused)
                .onSubmit(onCapture)
                .accessibilityLabel("Yeni iş ekle")
        }
    }

    private var addButton: some View {
        Button("Ekle", systemImage: "arrow.turn.down.left", action: onCapture)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

private struct InboxTaskRow: View {
    let task: TaskItem
    let onDelete: () -> Void

    var body: some View {
        AppCard(padding: AppSpacing.medium) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: task.status == .stopped ? "pause.circle.fill" : "circle.dashed")
                    .font(.title3)
                    .foregroundStyle(task.status == .stopped ? .orange : .blue)

                VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                    Text(task.title)
                        .font(.body.weight(.medium))
                        .lineLimit(2)

                    if task.status == .stopped {
                        AppStatusBadge(title: "Durduruldu", color: .orange)
                    } else if task.eisenhowerQuadrant != .unset {
                        Text(task.eisenhowerQuadrant.actionTitle)
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: AppSpacing.small)

                Menu {
                    Button("Sil", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 28, height: 28)
                }
                .menuStyle(.borderlessButton)
                .accessibilityLabel("İş seçenekleri")
            }
        }
    }
}
