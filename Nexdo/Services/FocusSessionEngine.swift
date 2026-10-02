import Foundation

/// Madde 16: Tüm `FocusSession` durum geçişleri burada — SwiftData'dan bağımsız, saf ve test edilebilir.
/// `FocusTimerService` bu motoru çağırır ve sonucu persist eder; View'lar bu motora hiç dokunmaz.
struct FocusSessionEngine {
    enum TransitionError: Error, Equatable {
        case invalidTransition
        case extensionLimitReached
    }

    func start(_ session: FocusSession, at date: Date = .now) {
        session.state = .running
        session.startDate = date
    }

    func pause(_ session: FocusSession, at date: Date = .now) throws {
        guard session.state == .running else { throw TransitionError.invalidTransition }
        session.state = .paused
        session.pausedAt = date
    }

    func resume(_ session: FocusSession, at date: Date = .now) throws {
        guard session.state == .paused, let pausedAt = session.pausedAt else {
            throw TransitionError.invalidTransition
        }
        session.accumulatedPauseDuration += date.timeIntervalSince(pausedAt)
        session.pausedAt = nil
        session.state = .running
    }

    /// `running` durumundayken süre dolmuşsa `expired`'a geçirir. Sleep/wake veya relaunch
    /// sonrası ilk çağrıda, çok büyük bir `elapsedTime` ile de doğru şekilde tetiklenir.
    @discardableResult
    func checkExpiry(_ session: FocusSession, at date: Date = .now) -> Bool {
        guard session.state == .running, session.remainingTime(at: date) <= 0 else { return false }
        session.state = .expired
        return true
    }

    /// Madde 17: sınırsız uzatma verilmez — sadece `expired` durumunda ve bir defaya mahsus.
    func extend(_ session: FocusSession, by duration: TimeInterval, at date: Date = .now) throws {
        guard session.state == .expired else { throw TransitionError.invalidTransition }
        guard session.extensionCount == 0 else { throw TransitionError.extensionLimitReached }
        session.plannedDuration += duration
        session.extensionCount += 1
        session.state = .running
    }

    func complete(_ session: FocusSession, at date: Date = .now) throws {
        guard session.state == .running || session.state == .expired else {
            throw TransitionError.invalidTransition
        }
        session.state = .completed
        session.endedAt = date
    }

    func stop(_ session: FocusSession, at date: Date = .now) throws {
        guard session.state != .completed && session.state != .stopped else {
            throw TransitionError.invalidTransition
        }
        session.state = .stopped
        session.endedAt = date
    }
}
