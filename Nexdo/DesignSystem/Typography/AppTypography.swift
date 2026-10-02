import SwiftUI

enum AppTypography {
    static let pageTitle = Font.largeTitle.weight(.bold)
    static let title = Font.title2.weight(.semibold)
    static let sectionTitle = Font.headline.weight(.semibold)
    static let body = Font.body
    static let caption = Font.caption
    static let overline = Font.caption2.weight(.semibold)
    static let timer = Font.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit()
}
