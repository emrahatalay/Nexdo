import SwiftUI

/// Madde 8 Step 4-5: timebox seçimi (preset + özel) ve ilk hareket.
struct PlannedTaskRowView: View {
    let task: TaskItem
    let onSetTimebox: (Int) -> Void
    let onSetFirstAction: (String) -> Void
    let onRemove: () -> Void

    @State private var firstActionText: String
    @State private var isEditingFirstAction = false
    @State private var isEditingCustomDuration = false
    @State private var customMinutes = 20

    private static let presets = [15, 25, 30, 45, 60, 90]

    init(
        task: TaskItem,
        onSetTimebox: @escaping (Int) -> Void,
        onSetFirstAction: @escaping (String) -> Void,
        onRemove: @escaping () -> Void
    ) {
        self.task = task
        self.onSetTimebox = onSetTimebox
        self.onSetFirstAction = onSetFirstAction
        self.onRemove = onRemove
        _firstActionText = State(initialValue: task.firstAction ?? "")
    }

    private var selectedMinutes: Int? {
        task.estimatedDuration.map { Int($0 / 60) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack {
                Text(task.title)
                    .font(AppTypography.body)
                Spacer()
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Yarından çıkar")
            }

            HStack(spacing: AppSpacing.xSmall) {
                ForEach(Self.presets, id: \.self) { minutes in
                    Button("\(minutes) dk") { onSetTimebox(minutes) }
                        .buttonStyle(.bordered)
                        .tint(selectedMinutes == minutes ? .accentColor : nil)
                }
                Button("Özel…") { isEditingCustomDuration = true }
                    .buttonStyle(.bordered)
            }

            if isEditingCustomDuration {
                HStack {
                    Stepper("\(customMinutes) dk", value: $customMinutes, in: 5...240, step: 5)
                    Button("Uygula") {
                        onSetTimebox(customMinutes)
                        isEditingCustomDuration = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if isEditingFirstAction {
                TextField("İlk hareket (örn. Unity'yi aç → CombatScene)", text: $firstActionText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        onSetFirstAction(firstActionText)
                        isEditingFirstAction = false
                    }
            } else {
                Button {
                    isEditingFirstAction = true
                } label: {
                    Label(task.firstAction ?? "İlk hareketi belirle", systemImage: "arrow.forward.circle")
                        .font(AppTypography.caption)
                        .foregroundStyle(task.firstAction == nil ? .secondary : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }
}
