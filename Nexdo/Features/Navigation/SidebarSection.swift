import Foundation

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
        case .today: "sun.max"
        case .inbox: "tray"
        case .planning: "moon.stars"
        case .focus: "scope"
        case .routines: "repeat"
        case .history: "clock.arrow.circlepath"
        }
    }
}
