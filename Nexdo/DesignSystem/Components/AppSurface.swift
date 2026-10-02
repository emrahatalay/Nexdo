import SwiftUI

struct AppPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            content
                .frame(maxWidth: AppSpacing.pageMaxWidth, alignment: .leading)
                .padding(.horizontal, AppSpacing.large)
                .padding(.vertical, AppSpacing.large)
                .frame(maxWidth: .infinity)
        }
        .background(AppBackground())
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.055),
                Color.clear,
                Color.secondary.opacity(0.035)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

struct AppCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.large
    let content: Content

    init(padding: CGFloat = AppSpacing.large, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.opacity(0.78), in: RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppSpacing.cardCornerRadius)
                    .stroke(.quaternary, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.045), radius: 18, y: 8)
    }
}

struct AppSectionHeader: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let systemImage: String?

    init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        systemImage: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.small) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 24, height: 24)
                    .background(Color.accentColor.opacity(0.11), in: RoundedRectangle(cornerRadius: 7))
            }

            VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                Text(title)
                    .font(AppTypography.sectionTitle)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }
}

struct AppStatusBadge: View {
    let title: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(title)
            .font(AppTypography.overline)
            .foregroundStyle(color)
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xSmall)
            .background(color.opacity(0.11), in: Capsule())
    }
}
