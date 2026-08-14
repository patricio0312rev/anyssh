import Highlighting
import SwiftUI

extension Theme.Code {
    public static func syntax(_ role: SyntaxRole) -> Color {
        switch role {
        case .keyword: Color.srgb(Hex.red)
        case .string: Color.srgb(Hex.yellow)
        case .function: Color.srgb(Hex.green)
        case .type: Color.srgb(Hex.cyan)
        case .constant: Color.srgb(Hex.purple)
        case .property: Color.srgb(Hex.orange)
        case .comment: Color.srgb(Hex.brightBlack)
        case .plain: foreground
        }
    }
}
