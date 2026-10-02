import SwiftUI

struct InboxView: View {
    var body: some View {
        ContentUnavailableView(
            "Her şey işlendi.",
            systemImage: "tray",
            description: Text("Yeni bir iş geldiğinde buraya bırak.")
        )
        .navigationTitle(SidebarSection.inbox.title)
    }
}
