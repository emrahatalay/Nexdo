import Foundation
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
    @FocusState private var isFirstActionFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            HStack(alignment: .top, spacing: AppSpacing.small) {
                Image(systemName: selectedMinutes == nil ? "circle.dashed" : "checkmark.circle.fill")
                    .foregroundStyle(selectedMinutes == nil ? Color.orange : Color.green)
                    .font(.title3)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text(task.title)
                        .font(.body.weight(.semibold))
                    HStack(spacing: AppSpacing.small) {
                        Label(startTime, systemImage: "clock")
                        if let selectedMinutes {
                            Label("\(selectedMinutes) dk", systemImage: "hourglass")
                        } else {
                            Label("Süre gerekli", systemImage: "exclamationmark.circle")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Yarından Çıkar", systemImage: "arrow.uturn.backward", role: .destructive, action: onRemove)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .foregroundStyle(.secondary)
                .help("Yarının planından çıkar")
            }

            VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                Text("Ne kadar zaman ayıracaksın?")
                    .font(AppTypography.caption.weight(.semibold))
                HStack(spacing: AppSpacing.xSmall) {
                    ForEach(Self.presets, id: \.self) { minutes in
                        Button("\(minutes)") { onSetTimebox(minutes) }
                            .buttonStyle(.bordered)
                            .tint(selectedMinutes == minutes ? .accentColor : .secondary)
                            .help("\(minutes) dakika")
                    }
                    Button("Özel…") { isEditingCustomDuration.toggle() }
                        .buttonStyle(.bordered)
                }
            }

            if isEditingCustomDuration {
                HStack(spacing: AppSpacing.small) {
                    Stepper("\(customMinutes) dakika", value: $customMinutes, in: 5...240, step: 5)
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
                    .focused($isFirstActionFocused)
                    .onSubmit {
                        onSetFirstAction(firstActionText)
                        isEditingFirstAction = false
                    }
            } else {
                Button {
                    isEditingFirstAction = true
                    isFirstActionFocused = true
                } label: {
                    Label(task.firstAction ?? "Başlamak için ilk somut hareketi yaz", systemImage: "play.circle")
                        .font(AppTypography.caption)
                        .foregroundStyle(task.firstAction == nil ? .secondary : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, AppSpacing.small)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isEditingCustomDuration)
        .animation(reduceMotion ? nil : .snappy(duration: 0.25), value: isEditingFirstAction)
    }

    private var startTime: String {
        guard let scheduledStart = task.scheduledStart else { return "Saat bekleniyor" }
        return scheduledStart.formatted(
            .dateTime.hour().minute().locale(Locale(identifier: "tr_TR"))
        )
    }
}
