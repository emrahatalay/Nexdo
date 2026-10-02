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
    private(set) var countdownText = "00:00"
    private(set) var menuBarText = "◎"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        activeSession = Self.fetchResumableSession(in: modelContext)

        if let session = activeSession {
            engine.checkExpiry(session)
            updateDisplay()
            save()
            if session.state == .running {
                scheduleExpiryChecks()
            }
        }
    }

    func start(for task: TaskItem) {
        guard activeSession == nil else { return }
        let defaultMinutes = UserDefaults.standard.integer(forKey: AppSettingsKey.defaultTimeboxMinutes)
        let duration = task.estimatedDuration ?? TimeInterval(defaultMinutes * 60)
        let session = FocusSession(task: task, plannedDuration: duration)
        engine.start(session)
        task.status = .active
        task.startedAt = .now
        modelContext.insert(session)
        activeSession = session
        updateDisplay()
        save()
        scheduleExpiryChecks()
        NotificationService.shared.notifyFocusStarted(taskTitle: task.title)
    }

    func pause() {
        guard let session = activeSession else { return }
        try? engine.pause(session)
        stopExpiryChecks()
        updateDisplay()
        save()
    }

    func resume() {
        guard let session = activeSession else { return }
        try? engine.resume(session)
        updateDisplay()
        save()
        scheduleExpiryChecks()
    }

    func refreshExpiry(at date: Date = .now) {
        guard let session = activeSession else { return }
        if engine.checkExpiry(session, at: date) {
            save()
            NotificationService.shared.notifyTimeboxCompleted(minutes: Int(session.plannedDuration / 60))
        }
    }

    /// İkinci uzatma talebi sessizce yok sayılır; UI bu durumda "yeniden planla" mesajını göstermelidir.
    func requestExtension() {
        guard let session = activeSession else { return }
        let extensionMinutes = UserDefaults.standard.integer(forKey: AppSettingsKey.extensionMinutes)
        try? engine.extend(session, by: TimeInterval(extensionMinutes * 60))
        updateDisplay()
        save()
        scheduleExpiryChecks()
    }

    func complete() {
        finish(outcome: .completed)
    }

    func stop() {
        finish(outcome: .stopped)
    }

    func canDeferActiveTask(at date: Date = .now) -> Bool {
        guard let session = activeSession, session.plannedDuration > 0 else { return false }
        return session.elapsedTime(at: date) / session.plannedDuration <= 0.1
    }

    /// During the first 10% of a timebox, the user can decide this is not the right task
    /// for now. The attempt is discarded, the task stays in today's plan, and moves to the end.
    @discardableResult
    func deferActiveTask(at date: Date = .now) -> Bool {
        guard let session = activeSession,
              canDeferActiveTask(at: date),
              let task = session.task else { return false }

        do {
            try engine.stop(session, at: date)
        } catch {
            return false
        }

        task.status = .planned
        task.startedAt = nil
        task.updatedAt = date

        if let plannedDate = task.plannedDate {
            let allTasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
            let todaysTasks = allTasks.filter {
                $0.plannedDate == plannedDate && ($0.status == .planned || $0.status == .active)
            }
            task.sortOrder = (todaysTasks.filter { $0.id != task.id }.map(\.sortOrder).max() ?? -1) + 1
            reschedule(tasks: todaysTasks, from: date)
        }

        // A very short reprioritization is not recorded as a stopped historical session.
        modelContext.delete(session)
        activeSession = nil
        stopExpiryChecks()
        updateDisplay(at: date)
        save()
        return true
    }

    /// Stops the current attempt and immediately starts the selected task.
    @discardableResult
    func switchTo(_ task: TaskItem) -> Bool {
        guard activeSession?.task?.id != task.id else { return false }
        if activeSession != nil {
            if canDeferActiveTask() {
                guard deferActiveTask() else { return false }
            } else {
                stop()
            }
        }
        start(for: task)
        return activeSession?.task?.id == task.id
    }

    private func reschedule(tasks: [TaskItem], from date: Date) {
        var cursor = date
        for task in tasks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let duration = task.estimatedDuration ?? 0
            task.scheduledStart = cursor
            cursor = cursor.addingTimeInterval(duration)
            task.scheduledEnd = cursor
        }
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
            task.updatedAt = .now

            if outcome == .completed {
                task.status = .completed
                task.completedAt = .now
            } else {
                // Madde 17: "Kalan kısmı tekrar planlamak mümkün olur." Quadrant/schedule
                // sıfırlanır ki Inbox ve Akşam Planı bu görevi yeniden triyaj için göstersin.
                task.status = .stopped
                task.eisenhowerQuadrant = .unset
                task.plannedDate = nil
                task.scheduledStart = nil
                task.scheduledEnd = nil
            }
        }

        activeSession = nil
        stopExpiryChecks()
        updateDisplay()
        save()
    }

    private func scheduleExpiryChecks() {
        expiryCheckTask?.cancel()
        expiryCheckTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                let date = Date.now
                self.refreshExpiry(at: date)
                self.updateDisplay(at: date)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    private func stopExpiryChecks() {
        expiryCheckTask?.cancel()
        expiryCheckTask = nil
    }

    private func updateDisplay(at date: Date = .now) {
        guard let session = activeSession,
              let task = session.task,
              session.state == .running || session.state == .paused else {
            countdownText = "00:00"
            menuBarText = "◎"
            return
        }

        let totalSeconds = Int(ceil(max(session.remainingTime(at: date), 0)))
        countdownText = String(
            format: "%02d:%02d",
            totalSeconds / 60,
            totalSeconds % 60
        )
        let shortTitle = task.title.count > 14
            ? String(task.title.prefix(14)) + "…"
            : task.title
        menuBarText = "◎ \(shortTitle) · \(countdownText)"
    }

    private static func fetchResumableSession(in context: ModelContext) -> FocusSession? {
        let sessions = (try? context.fetch(FetchDescriptor<FocusSession>())) ?? []
        return sessions.first { $0.state == .running || $0.state == .paused || $0.state == .expired }
    }

    private func save() {
        try? modelContext.save()
    }
}
