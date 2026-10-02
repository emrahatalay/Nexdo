import SwiftData
import SwiftUI

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt, order: .reverse) private var allTasks: [TaskItem]

    @State private var newTaskTitle = ""
    @State private var errorMessage: String?
    @FocusState private var isCaptureFieldFocused: Bool

    /// `TaskStatus` özel bir enum olduğundan `@Query(filter:)`'ın `#Predicate` makrosu
    /// karşılaştırmayı doğru genişletemiyor; bu yüzden filtre düz Swift closure'ı ile yapılıyor.
    private var inboxTasks: [TaskItem] {
        allTasks.filter { $0.status == .inbox }
    }

    private var repository: TaskRepository {
        SwiftDataTaskRepository(modelContext: modelContext)
    }

    var body: some View {
        VStack(spacing: 0) {
            captureField
            Divider()
            if inboxTasks.isEmpty {
                ContentUnavailableView(
                    "Her şey işlendi.",
                    systemImage: "tray",
                    description: Text("Yeni bir iş geldiğinde buraya bırak.")
                )
            } else {
                List {
                    ForEach(inboxTasks) { task in
                        HStack {
                            Text(task.title)
                            if task.eisenhowerQuadrant != .unset {
                                Spacer()
                                Text(task.eisenhowerQuadrant.actionTitle)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(SidebarSection.inbox.title)
        .alert(
            "Kaydedilemedi",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            ),
            actions: {
                Button("Tamam") { errorMessage = nil }
            },
            message: {
                Text(errorMessage ?? "")
            }
        )
    }

    private var captureField: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.secondary)
            TextField("Ne yapman gerekiyor?", text: $newTaskTitle)
                .textFieldStyle(.plain)
                .focused($isCaptureFieldFocused)
                .onSubmit(capture)
                .accessibilityLabel("Yeni iş ekle")
        }
        .padding(AppSpacing.medium)
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

    private func delete(at offsets: IndexSet) {
        do {
            for index in offsets {
                try repository.delete(inboxTasks[index])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
