import SwiftUI

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case today
    case inbox
    case planning
    case focus
    case routines
    case history

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Bugün"
        case .inbox: "İş Havuzu"
        case .planning: "Akşam Planı"
        case .focus: "Odak"
        case .routines: "Rutinler"
        case .history: "Geçmiş"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max.fill"
        case .inbox: "tray.fill"
        case .planning: "moon.stars.fill"
        case .focus: "scope"
        case .routines: "repeat.circle.fill"
        case .history: "clock.arrow.circlepath"
        }
    }

    var tint: Color {
        switch self {
        case .today: .orange
        case .inbox: .blue
        case .planning: .indigo
        case .focus: .purple
        case .routines: .green
        case .history: .teal
        }
    }
}
