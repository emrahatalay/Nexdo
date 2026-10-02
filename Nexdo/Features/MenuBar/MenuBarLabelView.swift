import SwiftUI

struct MenuBarLabelView: View {
    var body: some View {
        Text(AppEnvironment.shared.focusTimerService.menuBarText)
    }
}
