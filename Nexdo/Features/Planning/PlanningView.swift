import SwiftUI

struct PlanningView: View {
    var body: some View {
        ContentUnavailableView(
            "Yarın için henüz bir şey seçmedin.",
            systemImage: "moon.stars",
            description: Text("İş Havuzu'ndaki görevleri değerlendirip yarına taşı.")
        )
        .navigationTitle(SidebarSection.planning.title)
    }
}
