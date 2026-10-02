import SwiftUI

struct CapacityBarView: View {
    let capacity: CapacityResult
    let onAvailableChange: (Int) -> Void
    let onBufferChange: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            ViewThatFits {
                HStack(spacing: AppSpacing.medium) {
                    metrics
                }

                VStack(spacing: AppSpacing.small) {
                    HStack(spacing: AppSpacing.small) {
                        availableMetric
                        plannedMetric
                    }
                    HStack(spacing: AppSpacing.small) {
                        bufferMetric
                        remainingMetric
                    }
                }
            }

            ProgressView(
                value: min(Double(capacity.plannedTaskMinutes + capacity.routineMinutes), Double(max(capacity.availableMinutes, 1))),
                total: Double(max(capacity.availableMinutes, 1))
            )
            .progressViewStyle(.linear)
            .tint(capacity.overCapacity ? .red : .accentColor)
            .scaleEffect(y: 1.6)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: capacity.remainingMinutes)

            if let warning = overCapacityWarning {
                Label(warning, systemImage: "exclamationmark.triangle.fill")
                    .font(AppTypography.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, AppSpacing.xSmall)
    }

    @ViewBuilder
    private var metrics: some View {
        availableMetric
        plannedMetric
        bufferMetric
        remainingMetric
    }

    private var availableMetric: some View {
        CapacityMetric(
            label: "Kullanılabilir",
            minutes: capacity.availableMinutes,
            color: .blue,
            onChange: onAvailableChange
        )
    }

    private var plannedMetric: some View {
        CapacityMetric(
            label: "Planlanan",
            minutes: capacity.plannedTaskMinutes + capacity.routineMinutes,
            color: .accentColor
        )
    }

    private var bufferMetric: some View {
        CapacityMetric(
            label: "Tampon",
            minutes: capacity.bufferMinutes,
            color: .secondary,
            onChange: onBufferChange
        )
    }

    private var remainingMetric: some View {
        CapacityMetric(
            label: capacity.overCapacity ? "Aşım" : "Boşluk",
            minutes: abs(capacity.remainingMinutes),
            color: capacity.overCapacity ? .red : .green
        )
    }

    private var overCapacityWarning: String? {
        guard capacity.overCapacity else { return nil }
        let planned = capacity.plannedTaskMinutes + capacity.routineMinutes + capacity.bufferMinutes
        return "Yarın için \(Self.formatted(planned)) planladın ancak \(Self.formatted(capacity.availableMinutes)) kullanılabilir zaman belirledin."
    }

    static func formatted(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 && mins > 0 { return "\(hours) sa \(mins) dk" }
        if hours > 0 { return "\(hours) sa" }
        return "\(mins) dk"
    }
}

private struct CapacityMetric: View {
    let label: LocalizedStringKey
    let minutes: Int
    let color: Color
    var onChange: ((Int) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: AppSpacing.xSmall) {
                Text(CapacityBarView.formatted(minutes))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(color)
                    .contentTransition(.numericText())

                if let onChange {
                    Stepper(
                        "",
                        value: Binding(get: { minutes }, set: onChange),
                        in: 0...1440,
                        step: 15
                    )
                    .labelsHidden()
                    .controlSize(.small)
                    .accessibilityLabel(Text(label))
                }
            }
        }
        .padding(AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }
}
