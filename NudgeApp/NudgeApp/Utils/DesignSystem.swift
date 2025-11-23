import SwiftUI

struct DesignSystem {
    // MARK: - Colors
    struct Colors {
        static let white = Color.white
        static let black = Color.black
        static let softGray = Color(hex: "F5F5F5")
        static let mediumGray = Color(hex: "4F4F4F")
        static let accentBlue = Color(hex: "2B7FFF")
        static let lightBlueBackground = Color(hex: "EAF4FF")
    }

    // MARK: - Typography
    struct Typography {
        static let headerFont = Font.custom("Playfair Display", size: 28).weight(.bold)
        static let headerFontLarge = Font.custom("Playfair Display", size: 34).weight(.bold)

        static let bodyFont = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyFontMedium = Font.system(size: 16, weight: .medium, design: .default)

        static let promptFont = Font.system(size: 15, weight: .regular, design: .default)
        static let promptQuestionFont = Font.system(size: 13, weight: .medium, design: .default)

        static let buttonFont = Font.system(size: 17, weight: .semibold, design: .default)

        static let captionFont = Font.system(size: 13, weight: .regular, design: .default)
        static let smallFont = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Spacing
    struct Spacing {
        static let horizontalPadding: CGFloat = 24
        static let moduleSpacing: CGFloat = 32
        static let inlineSpacing: CGFloat = 16
        static let smallSpacing: CGFloat = 8
        static let tightSpacing: CGFloat = 4
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let card: CGFloat = 12
        static let button: CGFloat = 24
        static let small: CGFloat = 8
    }

    // MARK: - Shadows
    struct Shadows {
        static let card: Shadow = Shadow(
            color: Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
