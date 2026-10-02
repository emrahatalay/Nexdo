import Foundation
import Observation
import SwiftData

/// Tek aktif oturum invariant'ını korur, `FocusSessionEngine`'i çağırıp sonucu persist eder.
/// Expiry kontrolü View'ların render döngüsünden değil, kendi iç zamanlayıcısından sürülür
/// (Madde 16: "Timer logic'i View içinde yazma").
@MainActor
@Observable
final class FocusTimerService {
    private let modelContext: ModelContext
    private let engine = FocusSessionEngine()
    private var expiryCheckTask: Task<Void, Never>?

    private(set) var activeSession: FocusSession?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        activeSession = Self.fetchResumableSession(in: modelContext)

        if let session = activeSession {
            engine.checkExpiry(session)
            save()
            if session.state == .running {
                scheduleExpiryChecks()
            }
        }
    }

    func start(for task: TaskItem) {
        guard activeSession == nil else { return }
        let duration = task.estimatedDuration ?? 25 * 60
        let session = FocusSession(task: task, plannedDuration: duration)
        engine.start(session)
        task.status = .active
        task.startedAt = .now
        modelContext.insert(session)
        activeSession = session
        save()
        scheduleExpiryChecks()
    }

    func pause() {
        guard let session = activeSession else { return }
        try? engine.pause(session)
        save()
    }

    func resume() {
        guard let session = activeSession else { return }
        try? engine.resume(session)
        save()
    }

    func refreshExpiry(at date: Date = .now) {
        guard let session = activeSession else { return }
        if engine.checkExpiry(session, at: date) {
            save()
        }
    }

    /// İkinci uzatma talebi sessizce yok sayılır; UI bu durumda "yeniden planla" mesajını göstermelidir.
    func requestExtension() {
        guard let session = activeSession else { return }
        try? engine.extend(session, by: 15 * 60)
        save()
    }

    func complete() {
        finish(outcome: .completed)
    }

    func stop() {
        finish(outcome: .stopped)
    }

    private func finish(outcome: FocusSessionState) {
        guard let session = activeSession else { return }
        do {
            if outcome == .completed {
                try engine.complete(session)
            } else {
                try engine.stop(session)
            }
        } catch {
            return
        }

        if let task = session.task {
            task.actualDuration += session.elapsedTime(at: .now)
            task.status = outcome == .completed ? .completed : .stopped
            task.completedAt = outcome == .completed ? .now : nil
            task.updatedAt = .now
        }

        activeSession = nil
        stopExpiryChecks()
        save()
    }

    private func scheduleExpiryChecks() {
        expiryCheckTask?.cancel()
        expiryCheckTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.refreshExpiry()
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopExpiryChecks() {
        expiryCheckTask?.cancel()
        expiryCheckTask = nil
    }

    private static func fetchResumableSession(in context: ModelContext) -> FocusSession? {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        return sessions.first { $0.state == .running || $0.state == .paused || $0.state == .expired }
    }

    private func save() {
        try? modelContext.save()
    }
}
