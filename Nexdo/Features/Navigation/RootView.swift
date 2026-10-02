import SwiftUI

struct RootView: View {
    @Bindable private var navigationState = AppEnvironment.shared.navigationState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarSection.allCases, selection: $navigationState.selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Önce Ne, Sonra Ne Kadar")
        } detail: {
            detailView(for: navigationState.selection)
        }
        .onChange(of: navigationState.selection) { _, newValue in
            // Madde 14: Focus Mode'da sidebar dikkat dağıtmamalı.
            columnVisibility = (newValue == .focus) ? .detailOnly : .all
        }
    }

    @ViewBuilder
    private func detailView(for section: SidebarSection?) -> some View {
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
