import Foundation

enum EisenhowerQuadrant: String, Codable, CaseIterable {
    case doNow
    case schedule
    case delegate
    case eliminate
    case unset

    static func classify(isImportant: Bool, isUrgent: Bool) -> EisenhowerQuadrant {
        switch (isImportant, isUrgent) {
        case (true, true): .doNow
        case (true, false): .schedule
        case (false, true): .delegate
        case (false, false): .eliminate
        }
    }

    var actionTitle: String {
        switch self {
        case .doNow: "Yap"
        case .schedule: "Planla"
        case .delegate: "Devret"
        case .eliminate: "Ele"
        case .unset: "Belirsiz"
        }
    }

    /// doNow/schedule yarının planına eklenir; delegate/eliminate kullanıcı kararına bırakılır (otomatik silinmez).
    var isEligibleForTomorrow: Bool {
        self == .doNow || self == .schedule
    }
}
