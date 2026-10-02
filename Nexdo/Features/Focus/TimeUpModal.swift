import SwiftUI

/// Madde 17: süre dolunca otomatik ek süre verilmez — kullanıcı üç seçenekten birini seçer.
struct TimeUpModal: View {
    let canExtend: Bool
    let onComplete: () -> Void
    let onStop: () -> Void
    let onExtend: () -> Void

    var body: some View {
        VStack(spacing: AppSpacing.large) {
            VStack(spacing: AppSpacing.xSmall) {
                Text("Zaman doldu.")
                    .font(.largeTitle.bold())
                Text("Şimdi bir karar ver.")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppSpacing.small) {
                Button("Bitti") { onComplete() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                Button("Burada Durdum") { onStop() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                if canExtend {
                    Button("+15 Dakika") { onExtend() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Bu iş tahmin edilenden uzun sürüyor. Kalan kısmı yeniden planla.")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(AppSpacing.xLarge)
        .frame(width: 360)
        .interactiveDismissDisabled()
    }
}
