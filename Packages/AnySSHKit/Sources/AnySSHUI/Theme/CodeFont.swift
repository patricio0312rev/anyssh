import SwiftUI

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public enum CodeFont {
    public static let defaultSize: CGFloat = 13

    private static let candidates = [
        "JetBrainsMonoNF-Regular",
        "JetBrainsMonoNerdFont-Regular",
        "JetBrainsMono-Regular",
    ]

    public static func font(size: CGFloat) -> Font {
        #if canImport(UIKit)
        Font(platformFont(size: size) as UIFont)
        #else
        Font(platformFont(size: size) as NSFont)
        #endif
    }

    #if canImport(UIKit)
    public static func platformFont(size: CGFloat) -> UIFont {
        candidates.lazy.compactMap { UIFont(name: $0, size: size) }.first
            ?? UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
    #else
    public static func platformFont(size: CGFloat) -> NSFont {
        candidates.lazy.compactMap { NSFont(name: $0, size: size) }.first
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
    }
    #endif
}

extension Theme {
    public static func code(size: CGFloat = CodeFont.defaultSize) -> Font {
        CodeFont.font(size: size)
    }
}
