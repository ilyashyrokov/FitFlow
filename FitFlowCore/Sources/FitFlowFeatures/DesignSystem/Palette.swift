import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum FitFlowPalette {
    public static let canvas = adaptive(light: 0xF2F4F0, dark: 0x111C20)
    public static let surface = adaptive(light: 0xFBFCF9, dark: 0x1B292E)
    public static let primaryText = adaptive(light: 0x162D35, dark: 0xEAF1ED)
    public static let secondaryText = adaptive(light: 0x65767A, dark: 0xA4B1B1)
    public static let border = adaptive(light: 0xDCE3DF, dark: 0x35464A)
    public static let brandInk = Color(hex: 0x162D35)
    public static let teal = adaptive(light: 0x08766F, dark: 0x54C8B0)
    public static let lime = Color(hex: 0xD9F16A)
    public static let orange = Color(hex: 0xE76D49)
    public static let softMint = adaptive(light: 0xDCEEE7, dark: 0x234239)
    public static let softPeach = adaptive(light: 0xF6E8DF, dark: 0x492F29)

    private static func adaptive(light: UInt, dark: UInt) -> Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
        #else
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(hex: dark)
                : NSColor(hex: light)
        })
        #endif
    }
}

#if canImport(UIKit)
private extension UIColor {
    convenience init(hex: UInt) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    convenience init(hex: UInt) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
#endif

private extension Color {
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
