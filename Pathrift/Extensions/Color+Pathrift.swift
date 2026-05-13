import SwiftUI
import SpriteKit

extension Color {
    static let pathriftBackground     = Color(hex: "#0A0A0F")
    static let pathriftNeonBlue       = Color(hex: "#00C8FF")
    static let pathriftGold           = Color(hex: "#FFD700")
    static let pathriftDanger         = Color(hex: "#FF2D55")
    static let pathriftSuccess        = Color(hex: "#30D158")
    static let pathriftSurface        = Color(hex: "#12121A")
    static let pathriftTextPrimary    = Color.white
    static let pathriftTextSecondary  = Color(hex: "#8E8E93")
    static let pathriftPurple         = Color(hex: "#8B4FFF")
    static let pathriftOrange         = Color(hex: "#FF6B00")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
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

extension TowerType {
    var swiftUIColor: Color {
        switch self {
        case .bolt:  return Color(red: 0.0,  green: 0.78, blue: 1.0)
        case .blast: return Color(red: 1.0,  green: 0.42, blue: 0.0)
        case .frost: return Color(red: 0.55, green: 0.31, blue: 1.0)
        }
    }
}

extension SKColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
