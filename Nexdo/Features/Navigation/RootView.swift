import SwiftUI

struct RootView: View {
    @State private var selection: SidebarSection? = .today

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Önce Ne, Sonra Ne Kadar")
        } detail: {
            detailView(for: selection)
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
