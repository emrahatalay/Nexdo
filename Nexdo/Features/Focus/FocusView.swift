import SwiftData
import SwiftUI

/// Madde 14: son derece minimal. Task title, first action, kalan süre, Pause, Complete,
/// Can't Start — başka hiçbir şey gösterilmez.
struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showPostponeSheet = false
    @State private var showExpiredModal = false

    private var timerService: FocusTimerService { AppEnvironment.shared.focusTimerService }

    var body: some View {
        content
        .sheet(isPresented: $showPostponeSheet) {
            if let task = timerService.activeSession?.task {
                PostponeReasonSheet(task: task) { reason in
                    timerService.stop()
                    PostponementRecorder().record(task: task, reason: reason, in: modelContext)
                    showPostponeSheet = false
                    exitFocus()
                }
            }
        }
        .sheet(isPresented: $showExpiredModal) {
            if let session = timerService.activeSession {
                TimeUpModal(
                    canExtend: session.extensionCount == 0,
                    onComplete: { timerService.complete(); exitFocus() },
                    onStop: { timerService.stop(); exitFocus() },
                    onExtend: { timerService.requestExtension() }
                )
            }
        }
        .onChange(of: timerService.activeSession?.state, initial: true) { _, newState in
            showExpiredModal = (newState == .expired)
        }
    }

    @ViewBuilder
    private var content: some View {
        let date = timerService.tickDate
        if let session = timerService.activeSession, let task = session.task {
            VStack(spacing: AppSpacing.large) {
                Spacer()

                Text(task.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                if let firstAction = task.firstAction {
                    Label(firstAction, systemImage: "arrow.forward.circle")
                        .foregroundStyle(.secondary)
                }

                Text(formattedRemaining(session.remainingTime(at: date)))
                    .font(AppTypography.timer)
                    .foregroundStyle(session.state == .paused ? .secondary : .primary)
                    .accessibilityLabel("Kalan süre \(Int(max(session.remainingTime(at: date), 0) / 60)) dakika")

                HStack(spacing: AppSpacing.large) {
                    Button(session.state == .paused ? "Devam Et" : "Duraklat") {
                        if session.state == .paused {
                            timerService.resume()
                        } else {
                            timerService.pause()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .keyboardShortcut(.space, modifiers: [])

                    Button("Bitti") {
                        timerService.complete()
                        exitFocus()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: [.command, .shift])
                }

                Button("Şimdi yapamıyorum") {
                    showPostponeSheet = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer()

                Button("Odaktan Çık") { exitFocus() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.xLarge)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ContentUnavailableView(
                "Aktif bir odak oturumu yok",
                systemImage: "scope",
                description: Text("Bugün ekranından bir işe başladığında burada göreceksin.")
            )
        }
    }

    private func exitFocus() {
        AppEnvironment.shared.navigationState.selection = .today
    }

    private func formattedRemaining(_ interval: TimeInterval) -> String {
        let clamped = max(interval, 0)
        return String(format: "%02d:%02d", Int(clamped) / 60, Int(clamped) % 60)
    }
}
