import SwiftUI

extension Theme.Code {
    public enum Diff {
        public static let added = Color.srgb(Theme.Code.Hex.green)
        public static let removed = Color.srgb(Theme.Code.Hex.red)
        public static let addedFill = Color.srgb(Theme.Code.Hex.green, opacity: 0.13)
        public static let addedEmphasis = Color.srgb(Theme.Code.Hex.green, opacity: 0.26)
        public static let removedFill = Color.srgb(Theme.Code.Hex.red, opacity: 0.13)
        public static let removedEmphasis = Color.srgb(Theme.Code.Hex.red, opacity: 0.26)
        public static let hunkHeader = Color.srgb(Theme.Code.Hex.purple)
        public static let hunkHeaderBackground = Color.srgb(Theme.Code.Hex.gutter)
    }
}
