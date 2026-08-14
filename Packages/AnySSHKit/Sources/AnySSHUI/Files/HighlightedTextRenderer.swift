import AnySSHCore
import Foundation
import Highlighting
import SwiftUI

#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

public protocol HighlightedTextRendering: Sendable {
    func attributed(blob: String, tokens: [LineTokens]) -> AttributedString
}

public struct HighlightedTextRenderer: HighlightedTextRendering {
    public let size: CGFloat

    public init(size: CGFloat = CodeFont.defaultSize) {
        self.size = size
    }

    public func attributed(line: String, tokens: LineTokens?) -> AttributedString {
        let document = NSMutableAttributedString(string: line, attributes: baseAttributes)
        let length = (line as NSString).length
        for span in tokens?.spans ?? [] {
            let start = span.range.lowerBound
            guard start < length else { continue }
            let count = min(span.range.count, length - start)
            document.addAttribute(
                .foregroundColor,
                value: Self.platformColor(for: span.scope),
                range: NSRange(location: start, length: count)
            )
        }
        return AttributedString(document)
    }

    public func attributed(blob: String, tokens: [LineTokens]) -> AttributedString {
        let lines = blob.split(separator: "\n", omittingEmptySubsequences: false)
            .dropLast(blob.hasSuffix("\n") ? 1 : 0)
        let document = NSMutableAttributedString()
        var utf16Offset = 0
        for (index, line) in lines.enumerated() {
            let text = String(line) + (index < lines.count - 1 ? "\n" : "")
            document.append(NSAttributedString(string: text, attributes: baseAttributes))
            if index < tokens.count {
                for span in tokens[index].spans {
                    document.addAttribute(
                        .foregroundColor,
                        value: Self.platformColor(for: span.scope),
                        range: NSRange(
                            location: utf16Offset + span.range.lowerBound,
                            length: span.range.count
                        )
                    )
                }
            }
            utf16Offset += (text as NSString).length
        }
        return AttributedString(document)
    }

    private var baseAttributes: [NSAttributedString.Key: Any] {
        [
            .font: CodeFont.platformFont(size: size),
            .foregroundColor: Self.foregroundPlatformColor,
        ]
    }

    #if canImport(UIKit)
    private static let foregroundPlatformColor = UIColor(Theme.Code.foreground)

    private static func platformColor(for scope: TokenScope) -> UIColor {
        UIColor(Theme.Code.syntax(SyntaxPalette.role(for: scope)))
    }
    #else
    private static let foregroundPlatformColor = NSColor(Theme.Code.foreground)

    private static func platformColor(for scope: TokenScope) -> NSColor {
        NSColor(Theme.Code.syntax(SyntaxPalette.role(for: scope)))
    }
    #endif
}
