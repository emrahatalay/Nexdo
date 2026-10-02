import SwiftUI

struct TodayView: View {
    var body: some View {
        ContentUnavailableView(
            "Bugün için plan hazırlanmadı.",
            systemImage: "sun.max",
            description: Text("Akşam Planı'ndan yarınını hazırla.")
        )
        .navigationTitle(SidebarSection.today.title)
    }
}
