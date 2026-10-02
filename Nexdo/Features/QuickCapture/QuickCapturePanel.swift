import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class QuickCapturePresentationState {
    var focusRequest = 0
}

struct QuickCapturePanel: View {
    let onDismiss: () -> Void
    let presentationState: QuickCapturePresentationState

    private let repository: TaskRepository

    @State private var title = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    init(
        modelContext: ModelContext,
        presentationState: QuickCapturePresentationState,
        onDismiss: @escaping () -> Void
    ) {
        self.repository = SwiftDataTaskRepository(modelContext: modelContext)
        self.presentationState = presentationState
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)

                TextField("Ne yapman gerekiyor?", text: $title)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isFocused)
                    .onSubmit(capture)
                    .accessibilityLabel("Hızlı görev ekle")

                Button("Ekle", systemImage: "arrow.turn.down.left", action: capture)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel("Görevi ekle")

                Button("Kapat", systemImage: "xmark", action: onDismiss)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .keyboardShortcut(.cancelAction)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            } else {
                Text("Return ile ekle · Esc ile kapat")
                    .font(AppTypography.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.medium)
        .frame(width: 520)
        .glassEffect(AppMaterials.floatingPanel, in: .rect(cornerRadius: 20))
        .onChange(of: presentationState.focusRequest, initial: true) {
            isFocused = true
        }
        .onExitCommand(perform: onDismiss)
    }

    private func capture() {
        do {
            if try repository.capture(title: title, source: .quickCapture) {
                title = ""
                errorMessage = nil
                onDismiss()
            }
        } catch {
            errorMessage = "Kaydedilemedi, tekrar dene."
        }
    }
}
