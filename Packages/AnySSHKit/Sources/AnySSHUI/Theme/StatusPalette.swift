import SwiftUI

public struct StatusPalette: Sendable {
    public let online: Color
    public let busy: Color
    public let attention: Color
    public let error: Color
    public let offline: Color

    public init() {
        #if canImport(UIKit)
        online = Color(uiColor: .systemGreen)
        busy = Color(uiColor: .systemYellow)
        attention = Color(uiColor: .systemOrange)
        error = Color(uiColor: .systemRed)
        offline = Color(uiColor: .systemGray)
        #else
        online = Color(nsColor: .systemGreen)
        busy = Color(nsColor: .systemYellow)
        attention = Color(nsColor: .systemOrange)
        error = Color(nsColor: .systemRed)
        offline = Color(nsColor: .systemGray)
        #endif
    }
}
