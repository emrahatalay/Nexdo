import SwiftUI

/// Madde 23: "◎ 45:00" / "◎ Combat · 37:42". Sadece görüntüleme amaçlı — state mutasyonu yok.
/// `FocusTimerService.tickDate`in Observable değişimi SwiftUI'nin yeniden çizimini tetikler;
/// burada ekstra bir `TimelineView`/`Timer` kurulmaz (MenuBarExtra ile çakışıyordu).
struct MenuBarLabelView: View {
    var body: some View {
        let timerService = AppEnvironment.shared.focusTimerService
        if let session = timerService.activeSession,
           let task = session.task,
           session.state == .running || session.state == .paused {
            Text("◎ \(shortTitle(task.title)) · \(formattedRemaining(session.remainingTime(at: timerService.tickDate)))")
        } else {
            Text("◎")
        }
    }

    private func shortTitle(_ title: String) -> String {
        title.count > 14 ? String(title.prefix(14)) + "…" : title
    }

    private func formattedRemaining(_ interval: TimeInterval) -> String {
        let clamped = max(interval, 0)
        return String(format: "%02d:%02d", Int(clamped) / 60, Int(clamped) % 60)
    }
}
