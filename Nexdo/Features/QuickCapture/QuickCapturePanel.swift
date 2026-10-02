import SwiftData
import SwiftUI

struct QuickCapturePanel: View {
    let onDismiss: () -> Void

    private let repository: TaskRepository

    @State private var title = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    init(modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        self.repository = SwiftDataTaskRepository(modelContext: modelContext)
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            HStack(spacing: AppSpacing.medium) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.secondary)
                TextField("Ne yapman gerekiyor?", text: $title)
                    .textFieldStyle(.plain)
                    .font(AppTypography.body)
                    .focused($isFocused)
                    .onSubmit(capture)
                    .accessibilityLabel("Hızlı görev ekle")
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, AppSpacing.large)
        .padding(.vertical, AppSpacing.medium)
        .frame(width: 480)
        .glassEffect(AppMaterials.floatingPanel, in: .rect(cornerRadius: 20))
        .onAppear { isFocused = true }
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
