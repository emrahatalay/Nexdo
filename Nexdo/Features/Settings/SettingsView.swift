import SwiftUI

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView(
            "Ayarlar henüz hazır değil.",
            systemImage: "gearshape"
        )
        .frame(minWidth: 400, minHeight: 300)
    }
}
