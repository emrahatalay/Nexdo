import SwiftUI

struct CapacityBarView: View {
    let capacity: CapacityResult
    let onAvailableChange: (Int) -> Void
    let onBufferChange: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            HStack(spacing: AppSpacing.large) {
                metric("Kullanılabilir", minutes: capacity.availableMinutes, stepper: true, onChange: onAvailableChange)
                metric("Planlanan", minutes: capacity.plannedTaskMinutes + capacity.routineMinutes)
                metric("Tampon", minutes: capacity.bufferMinutes, stepper: true, onChange: onBufferChange)
                metric(
                    capacity.overCapacity ? "Aşım" : "Boşluk",
                    minutes: abs(capacity.remainingMinutes),
                    tint: capacity.overCapacity ? .red : .secondary
                )
            }

            ProgressView(
                value: min(Double(capacity.plannedTaskMinutes + capacity.routineMinutes), Double(max(capacity.availableMinutes, 1))),
                total: Double(max(capacity.availableMinutes, 1))
            )
            .tint(capacity.overCapacity ? .red : .accentColor)

            if let warning = overCapacityWarning {
                Text(warning)
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var overCapacityWarning: String? {
        guard capacity.overCapacity else { return nil }
        let planned = capacity.plannedTaskMinutes + capacity.routineMinutes + capacity.bufferMinutes
        return "Yarın için \(Self.formatted(planned)) planladın ancak \(Self.formatted(capacity.availableMinutes)) kullanılabilir zaman belirledin."
    }

    private func metric(
        _ label: String,
        minutes: Int,
        tint: Color = .primary,
        stepper: Bool = false,
        onChange: ((Int) -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: AppSpacing.xSmall) {
                Text(Self.formatted(minutes))
                    .font(AppTypography.body.bold())
                    .foregroundStyle(tint)
                if stepper, let onChange {
                    Stepper(
                        "",
                        value: Binding(get: { minutes }, set: onChange),
                        in: 0...1440,
                        step: 15
                    )
                    .labelsHidden()
                    .accessibilityLabel("\(label) süresini ayarla")
                }
            }
        }
    }

    private static func formatted(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours) sa \(mins) dk" }
        if hours > 0 { return "\(hours) sa" }
        return "\(mins) dk"
    }
}
