import SwiftUI

public enum Theme {
    public static let surface = SurfacePalette()
    public static let text = TextPalette()
    public static let status = StatusPalette()

    public static let accentHex: UInt32 = 0xab9df2
    public static let accentPressedHex: UInt32 = 0x8f7fe0

    public static let accent = Color.srgb(accentHex)
    public static let accentPressed = Color.srgb(accentPressedHex)

    #if canImport(UIKit)
    public static let separator = Color(uiColor: .separator)
    public static let destructive = Color(uiColor: .systemRed)
    #else
    public static let separator = Color(nsColor: .separatorColor)
    public static let destructive = Color(nsColor: .systemRed)
    #endif
}
