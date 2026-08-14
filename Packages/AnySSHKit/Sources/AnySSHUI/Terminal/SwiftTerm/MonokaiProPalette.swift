import SwiftTerm

#if canImport(UIKit)
import UIKit
#endif

enum MonokaiProPalette {
    static var windowBackground: TerminalPlatformColor { background.platformColor }

    static func apply(to view: TerminalView) {
        view.installColors(ansi)
        view.nativeForegroundColor = foreground.platformColor
        view.nativeBackgroundColor = background.platformColor
        view.caretColor = cursor.platformColor
        view.caretTextColor = cursorText.platformColor
        view.selectedTextBackgroundColor = selectionBackground.platformColor
        view.selectedTextForegroundColor = selectionForeground.platformColor
        #if canImport(UIKit)
        view.selectionHandleColor = Theme.Code.Platform.selectionHandle
        view.keyboardDismissMode = .none
        view.layer.backgroundColor = background.platformColor.cgColor
        #endif
    }

    static let ansi: [SwiftTerm.Color] = Theme.Code.ansiHex.map { SwiftTerm.Color(hex: $0) }

    static let background = SwiftTerm.Color(hex: Theme.Code.Hex.canvas)
    static let foreground = SwiftTerm.Color(hex: Theme.Code.Hex.foreground)
    static let cursor = SwiftTerm.Color(hex: Theme.Code.Hex.cursor)
    static let cursorText = SwiftTerm.Color(hex: Theme.Code.Hex.cursorText)
    static let selectionBackground = SwiftTerm.Color(hex: Theme.Code.Hex.selectionBackground)
    static let selectionForeground = foreground
}

extension SwiftTerm.Color {
    convenience init(hex: UInt32) {
        self.init(
            red8: UInt16((hex >> 16) & 0xff),
            green8: UInt16((hex >> 8) & 0xff),
            blue8: UInt16(hex & 0xff)
        )
    }

    var platformColor: TerminalPlatformColor {
        #if canImport(UIKit)
        uiColor
        #else
        nsColor
        #endif
    }
}
