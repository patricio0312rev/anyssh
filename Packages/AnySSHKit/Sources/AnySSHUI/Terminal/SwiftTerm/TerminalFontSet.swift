import CoreText

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public struct TerminalFontSet {
    public let normal: TerminalPlatformFont
    public let bold: TerminalPlatformFont
    public let italic: TerminalPlatformFont
    public let boldItalic: TerminalPlatformFont

    public init(size: CGFloat = 13) {
        let regular = TerminalFontSet.monospaced(size: size, bold: false)
        let heavy = TerminalFontSet.monospaced(size: size, bold: true)
        normal = TerminalFontSet.withoutLigatures(regular)
        bold = TerminalFontSet.withoutLigatures(heavy)
        italic = TerminalFontSet.withoutLigatures(TerminalFontSet.slanted(regular))
        boldItalic = TerminalFontSet.withoutLigatures(TerminalFontSet.slanted(heavy))
    }

    private static func monospaced(size: CGFloat, bold: Bool) -> TerminalPlatformFont {
        let names = bold ? boldNames : regularNames
        if let bundled = names.lazy.compactMap({ TerminalPlatformFont(name: $0, size: size) }).first {
            return bundled
        }
        return TerminalPlatformFont.monospacedSystemFont(ofSize: size, weight: bold ? .bold : .regular)
    }

    private static let regularNames = [
        "JetBrainsMonoNF-Regular",
        "JetBrainsMonoNerdFont-Regular",
        "JetBrainsMono-Regular",
    ]

    private static let boldNames = [
        "JetBrainsMonoNF-Bold",
        "JetBrainsMonoNerdFont-Bold",
        "JetBrainsMono-Bold",
    ]

    private static func withoutLigatures(_ font: TerminalPlatformFont) -> TerminalPlatformFont {
        #if canImport(UIKit)
        let settings: [[UIFontDescriptor.FeatureKey: Int]] = [
            [.type: kLigaturesType, .selector: kCommonLigaturesOffSelector]
        ]
        let descriptor = font.fontDescriptor.addingAttributes([.featureSettings: settings])
        return UIFont(descriptor: descriptor, size: font.pointSize)
        #else
        let settings: [[NSFontDescriptor.FeatureKey: Int]] = [
            [.typeIdentifier: kLigaturesType, .selectorIdentifier: kCommonLigaturesOffSelector]
        ]
        let descriptor = font.fontDescriptor.addingAttributes([.featureSettings: settings])
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
        #endif
    }

    private static func slanted(_ font: TerminalPlatformFont) -> TerminalPlatformFont {
        #if canImport(UIKit)
        guard let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) else { return font }
        return UIFont(descriptor: descriptor, size: font.pointSize)
        #else
        let descriptor = font.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
        #endif
    }
}
