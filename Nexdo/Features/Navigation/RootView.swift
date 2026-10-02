import SwiftUI

struct RootView: View {
    @Bindable private var navigationState = AppEnvironment.shared.navigationState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            AppSidebar(selection: $navigationState.selection)
                .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 280)
        } detail: {
            DetailDestination(section: navigationState.selection)
                .frame(minWidth: 420, minHeight: 520)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: navigationState.selection) { _, newValue in
            columnVisibility = newValue == .focus ? .detailOnly : .all
        }
    }
}

private struct AppSidebar: View {
    @Binding var selection: SidebarSection?

    var body: some View {
        List(SidebarSection.allCases, selection: $selection) { section in
            NavigationLink(value: section) {
                HStack(spacing: AppSpacing.small) {
                    Image(systemName: section.systemImage)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(section.tint)
                        .frame(width: 28, height: 28)
                        .background(section.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

                    Text(section.title)
                        .font(.body.weight(selection == section ? .semibold : .regular))
                }
                .padding(.vertical, AppSpacing.xSmall)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Nexdo")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: AppSpacing.small) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.accentColor)
                Text("Sıradaki doğru işe odaklan")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(AppSpacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailDestination: View {
    let section: SidebarSection?

    var body: some View {
        switch section {
        case .today:
            TodayView()
        case .inbox:
            InboxView()
        case .planning:
            PlanningView()
        case .focus:
            FocusView()
        case .routines:
            RoutinesView()
        case .history:
            HistoryView()
        case nil:
            ContentUnavailableView("Bir bölüm seç", systemImage: "sidebar.left")
        }
    }
}
