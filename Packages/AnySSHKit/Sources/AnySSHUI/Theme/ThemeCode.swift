import SwiftUI

extension Theme {
    public enum Code {
        public enum Hex {
            public static let canvas: UInt32 = 0x2d2a2e
            public static let foreground: UInt32 = 0xfcfcfa
            public static let red: UInt32 = 0xff6188
            public static let green: UInt32 = 0xa9dc76
            public static let yellow: UInt32 = 0xffd866
            public static let orange: UInt32 = 0xfc9867
            public static let purple: UInt32 = 0xab9df2
            public static let cyan: UInt32 = 0x78dce8
            public static let brightBlack: UInt32 = 0x727072
            public static let cursor: UInt32 = 0xc1c0c0
            public static let cursorText: UInt32 = 0x8e8d8d
            public static let selectionBackground: UInt32 = 0x5b595c
            public static let gutter: UInt32 = 0x363338
        }

        public static let canvas = Color.srgb(Hex.canvas)
        public static let foreground = Color.srgb(Hex.foreground)
        public static let cursor = Color.srgb(Hex.cursor)
        public static let cursorText = Color.srgb(Hex.cursorText)
        public static let selectionBackground = Color.srgb(Hex.selectionBackground)
        public static let selectionForeground = foreground
        public static let gutter = Color.srgb(Hex.gutter)

        public static let ansiHex: [UInt32] = [
            Hex.canvas, Hex.red, Hex.green, Hex.yellow,
            Hex.orange, Hex.purple, Hex.cyan, Hex.foreground,
            Hex.brightBlack, Hex.red, Hex.green, Hex.yellow,
            Hex.orange, Hex.purple, Hex.cyan, Hex.foreground,
        ]

        public static let ansi: [Color] = ansiHex.map { Color.srgb($0) }
    }
}
