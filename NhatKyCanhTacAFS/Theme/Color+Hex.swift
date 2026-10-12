import SwiftUI

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1.0)
    }
}

extension Color {
    static let afsGreen = Color(hex: 0x2E7D32)
    static let afsGreenDark = Color(hex: 0x1B5E20)
    static let afsGreenLight = Color(hex: 0x4CAF50)
    static let afsLime = Color(hex: 0x8BC34A)
    static let afsBackground = Color(hex: 0xF1F8E9)
    static let afsCard = Color.white
    static let afsTextPrimary = Color(hex: 0x1B2A1C)
    static let afsTextSecondary = Color(hex: 0x5B6B5D)
    static let afsLine = Color(hex: 0xE2ECDA)
}
