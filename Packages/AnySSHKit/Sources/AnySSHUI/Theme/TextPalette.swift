import SwiftUI

public struct TextPalette: Sendable {
    public let primary: Color
    public let secondary: Color
    public let tertiary: Color

    public init() {
        #if canImport(UIKit)
        primary = Color(uiColor: .label)
        secondary = Color(uiColor: .secondaryLabel)
        tertiary = Color(uiColor: .tertiaryLabel)
        #else
        primary = Color(nsColor: .labelColor)
        secondary = Color(nsColor: .secondaryLabelColor)
        tertiary = Color(nsColor: .tertiaryLabelColor)
        #endif
    }
}
