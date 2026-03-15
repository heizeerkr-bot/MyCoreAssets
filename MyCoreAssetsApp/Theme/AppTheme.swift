import SwiftUI

// MARK: - Colors

extension Color {
    // Brand
    static let themePrimary = Color(hex: "1E88E5")
    static let themeDeep = Color(hex: "1565C0")
    static let themeLight = Color(hex: "E3F2FD")

    // Backgrounds
    static let pageBg = Color(hex: "F8FBFF")
    static let cardBg = Color.white
    static let divider = Color(hex: "E0E0E0")

    // Text
    static let textPrimary = Color(hex: "212121")
    static let textBody = Color(hex: "424242")
    static let textSecondary = Color(hex: "757575")
    static let textTertiary = Color(hex: "9E9E9E")

    // Valuation (green = undervalued = good, red = overvalued = bad)
    static let valuationDeepGreen = Color(hex: "43A047")
    static let valuationLightGreen = Color(hex: "7CB342")
    static let valuationNeutral = Color(hex: "78909C")
    static let valuationOrange = Color(hex: "FB8C00")
    static let valuationRed = Color(hex: "E53935")

    // Profit/Loss
    static let profitGreen = Color(hex: "43A047")
    static let lossRed = Color(hex: "E53935")
}

// MARK: - Hex Color Init

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    static let superLargeTitle = Font.system(size: 36, weight: .bold, design: .rounded)
    static let assetPrice = Font.system(size: 28, weight: .semibold)
    static let positionPercent = Font.system(size: 22, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 18, weight: .semibold)
    static let bodyText = Font.system(size: 16, weight: .regular)
    static let caption = Font.system(size: 14, weight: .regular)
    static let smallCaption = Font.system(size: 12, weight: .regular)
}

// MARK: - Spacing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
}
