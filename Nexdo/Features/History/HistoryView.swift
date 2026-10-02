import SwiftUI

struct HistoryView: View {
    var body: some View {
        ContentUnavailableView(
            "Henüz geçmiş veri yok.",
            systemImage: "clock.arrow.circlepath",
            description: Text("Tamamladığın günler burada birikecek.")
        )
        .navigationTitle(SidebarSection.history.title)
    }
}
