import Foundation
import SwiftData

protocol TaskRepository {
    func fetchInbox() throws -> [TaskItem]
    func fetchAll() throws -> [TaskItem]
    func save(_ task: TaskItem) throws
    func delete(_ task: TaskItem) throws
}

extension TaskRepository {
    /// Tek zorunlu alan `title`dır (Madde 4). Boş/boşluk-only başlıklar görmezden gelinir.
    /// Inbox ekranı ve Quick Capture paneli aynı yakalama yolunu paylaşır.
    @discardableResult
    func capture(title: String, source: TaskSource = .manual) throws -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        try save(TaskItem(title: trimmed, source: source))
        return true
    }
}

/// SwiftData `@Model` nesneleri bir `ModelContext`'e bağlıdır ve actor sınırları arasında
/// taşınamaz; bu nedenle repository de UI ile aynı `MainActor` üzerinde çalışır.
@MainActor
final class SwiftDataTaskRepository: TaskRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchInbox() throws -> [TaskItem] {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor).filter { $0.status == .inbox }
    }

    func fetchAll() throws -> [TaskItem] {
        try modelContext.fetch(FetchDescriptor<TaskItem>())
    }

    func save(_ task: TaskItem) throws {
        modelContext.insert(task)
        try modelContext.save()
    }

    func delete(_ task: TaskItem) throws {
        modelContext.delete(task)
        try modelContext.save()
    }
}
