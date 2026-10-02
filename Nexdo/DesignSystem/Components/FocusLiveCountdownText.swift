import SwiftUI

/// Displays a wall-clock-based countdown that SwiftUI updates automatically.
/// The end date includes accumulated pause time so suspend/resume remains accurate.
struct FocusLiveCountdownText: View {
    let session: FocusSession
    var showsHours = false

    var body: some View {
        if let startDate = session.startDate {
            Text(
                timerInterval: startDate...endDate(from: startDate),
                pauseTime: session.state == .paused ? session.pausedAt : nil,
                countsDown: true,
                showsHours: showsHours
            )
            .monospacedDigit()
        } else {
            Text("00:00")
                .monospacedDigit()
        }
    }

    private func endDate(from startDate: Date) -> Date {
        startDate.addingTimeInterval(
            session.plannedDuration + session.accumulatedPauseDuration
        )
    }
}
