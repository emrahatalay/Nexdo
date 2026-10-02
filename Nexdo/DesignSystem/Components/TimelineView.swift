import SwiftUI

/// Bugün ve Akşam Planı ekranları arasında paylaşılan zaman çizelgesi bloğu (Madde 11).
struct TimelineBlock: Identifiable {
    enum Kind {
        case task
        case routine
        case buffer
    }

    let id: UUID
    let startTime: Date
    let duration: TimeInterval
    let title: String
    let subtitle: String?
    let kind: Kind
}

struct TimelineView: View {
    let blocks: [TimelineBlock]

    var body: some View {
        if blocks.isEmpty {
            ContentUnavailableView(
                "Zaman çizelgesi boş",
                systemImage: "clock",
                description: Text("Görevler eklendiğinde burada sıralanacak.")
            )
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(blocks) { block in
                    row(for: block)
                    if block.id != blocks.last?.id {
                        Divider().padding(.leading, 64)
                    }
                }
            }
        }
    }

    private func row(for block: TimelineBlock) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.medium) {
            Text(block.startTime, format: .dateTime.hour().minute())
                .font(AppTypography.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            RoundedRectangle(cornerRadius: 2)
                .fill(color(for: block.kind))
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(block.title)
                    .font(AppTypography.body)
                    .foregroundStyle(block.kind == .buffer ? .secondary : .primary)
                if let subtitle = block.subtitle {
                    Text(subtitle)
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text("\(Int(block.duration / 60)) dk")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, AppSpacing.small)
    }

    private func color(for kind: TimelineBlock.Kind) -> Color {
        switch kind {
        case .task: .accentColor
        case .routine: .blue
        case .buffer: Color.secondary.opacity(0.4)
        }
    }
}
