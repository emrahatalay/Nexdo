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

                FocusLiveCountdownText(session: session)
                    .font(AppTypography.timer)
                    .foregroundStyle(session.state == .paused ? .secondary : .primary)
                    .contentTransition(.numericText(countsDown: true))

                ViewThatFits {
                    HStack(spacing: AppSpacing.small) {
                        FocusPauseButton(
                            isPaused: session.state == .paused,
                            onPause: timerService.pause,
                            onResume: timerService.resume
                        )
                        FocusCompleteButton {
                            timerService.complete()
                            exitFocus()
                        }
                    }

                    VStack(spacing: AppSpacing.small) {
                        FocusPauseButton(
                            isPaused: session.state == .paused,
                            onPause: timerService.pause,
                            onResume: timerService.resume
                        )
                        .frame(maxWidth: .infinity)
                        FocusCompleteButton {
                            timerService.complete()
                            exitFocus()
                        }
                        .frame(maxWidth: .infinity)
                    }
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
            .background(AppBackground())
        } else {
            ContentUnavailableView(
                "Aktif bir odak oturumu yok",
                systemImage: "scope",
                description: Text("Bugün ekranından bir işe başladığında burada göreceksin.")
            )
        }
    }

    private struct FocusPauseButton: View {
        let isPaused: Bool
        let onPause: () -> Void
        let onResume: () -> Void

        var body: some View {
            Button(isPaused ? "Devam Et" : "Duraklat", systemImage: isPaused ? "play.fill" : "pause.fill") {
                isPaused ? onResume() : onPause()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .keyboardShortcut(.space, modifiers: [])
        }
    }

    private struct FocusCompleteButton: View {
        let action: () -> Void

        var body: some View {
            Button("Bitti", systemImage: "checkmark", action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.return, modifiers: [.command, .shift])
        }
    }

    private func exitFocus() {
        AppEnvironment.shared.navigationState.selection = .today
    }

}
