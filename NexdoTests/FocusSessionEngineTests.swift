import Foundation
import Testing
@testable import Nexdo

struct FocusSessionEngineTests {
    private let engine = FocusSessionEngine()

    private func makeSession(plannedMinutes: Int = 25) -> FocusSession {
        let task = TaskItem(title: "Test görevi")
        return FocusSession(task: task, plannedDuration: TimeInterval(plannedMinutes * 60))
    }

    @Test func startSetsRunningAndStartDate() {
        let session = makeSession()
        let now = Date(timeIntervalSince1970: 1_000)
        engine.start(session, at: now)
        #expect(session.state == .running)
        #expect(session.startDate == now)
    }

    @Test func pauseFromRunningSucceeds() throws {
        let session = makeSession()
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)
        try engine.pause(session, at: start.addingTimeInterval(60))
        #expect(session.state == .paused)
        #expect(session.pausedAt == start.addingTimeInterval(60))
    }

    @Test func pauseFromNonRunningStateThrows() {
        let session = makeSession()
        #expect(throws: FocusSessionEngine.TransitionError.invalidTransition) {
            try engine.pause(session)
        }
    }

    @Test func resumeAccumulatesPauseDuration() throws {
        let session = makeSession()
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)
        try engine.pause(session, at: start.addingTimeInterval(60))
        try engine.resume(session, at: start.addingTimeInterval(90))

        #expect(session.state == .running)
        #expect(session.accumulatedPauseDuration == 30)
        #expect(session.pausedAt == nil)
    }

    @Test func remainingTimeIgnoresPausedDuration() throws {
        let session = makeSession(plannedMinutes: 10)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)
        // 2 dakika çalış, 5 dakika duraklat, sonra devam et.
        try engine.pause(session, at: start.addingTimeInterval(2 * 60))
        try engine.resume(session, at: start.addingTimeInterval(7 * 60))

        // Duvar saatinde 7 dakika geçti ama sadece 2 dakikası "elapsed" sayılmalı.
        let remaining = session.remainingTime(at: start.addingTimeInterval(7 * 60))
        #expect(remaining == 8 * 60)
    }

    @Test func checkExpiryTransitionsWhenTimeIsUp() {
        let session = makeSession(plannedMinutes: 25)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)

        let didExpire = engine.checkExpiry(session, at: start.addingTimeInterval(25 * 60 + 1))
        #expect(didExpire == true)
        #expect(session.state == .expired)
    }

    @Test func checkExpiryRecoversAfterLargeWallClockGap() {
        // Mac uykuya dalıp saatler sonra uyandı senaryosu (Madde 39): sayaç değil,
        // duvar saati farkı kullanıldığından tek bir kontrolle doğru sonuca "self-heal" eder.
        let session = makeSession(plannedMinutes: 25)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)

        let muchLater = start.addingTimeInterval(3 * 60 * 60)
        let didExpire = engine.checkExpiry(session, at: muchLater)

        #expect(didExpire == true)
        #expect(session.state == .expired)
        #expect(session.remainingTime(at: muchLater) < -(2 * 60 * 60))
    }

    @Test func firstExtensionSucceeds() throws {
        let session = makeSession(plannedMinutes: 25)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)
        engine.checkExpiry(session, at: start.addingTimeInterval(25 * 60 + 1))

        try engine.extend(session, by: 15 * 60)

        #expect(session.state == .running)
        #expect(session.extensionCount == 1)
        #expect(session.plannedDuration == TimeInterval(40 * 60))
    }

    @Test func secondExtensionIsRejected() throws {
        let session = makeSession(plannedMinutes: 25)
        let start = Date(timeIntervalSince1970: 0)
        engine.start(session, at: start)
        engine.checkExpiry(session, at: start.addingTimeInterval(25 * 60 + 1))
        try engine.extend(session, by: 15 * 60)
        engine.checkExpiry(session, at: start.addingTimeInterval(40 * 60 + 1))

        #expect(throws: FocusSessionEngine.TransitionError.extensionLimitReached) {
            try engine.extend(session, by: 15 * 60)
        }
    }

    @Test func completeFromRunningSucceeds() throws {
        let session = makeSession()
        engine.start(session)
        try engine.complete(session)
        #expect(session.state == .completed)
        #expect(session.endedAt != nil)
    }

    @Test func stopIsRejectedAfterCompletion() throws {
        let session = makeSession()
        engine.start(session)
        try engine.complete(session)

        #expect(throws: FocusSessionEngine.TransitionError.invalidTransition) {
            try engine.stop(session)
        }
    }
}
