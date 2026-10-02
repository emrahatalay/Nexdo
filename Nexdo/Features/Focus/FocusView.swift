import SwiftUI

struct FocusView: View {
    var body: some View {
        ContentUnavailableView(
            "Henüz bir göreve başlamadın.",
            systemImage: "scope",
            description: Text("Bugün ekranından bir işe başladığında burada göreceksin.")
        )
        .navigationTitle(SidebarSection.focus.title)
    }
}
