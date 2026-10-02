import SwiftUI

struct RoutinesView: View {
    var body: some View {
        ContentUnavailableView(
            "Henüz bir rutin yok.",
            systemImage: "repeat",
            description: Text("Düzenli tekrar eden alışkanlıklarını buraya ekle.")
        )
        .navigationTitle(SidebarSection.routines.title)
    }
}
