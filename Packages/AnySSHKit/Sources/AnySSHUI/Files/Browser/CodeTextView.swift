#if canImport(UIKit)
import AnySSHCore
import SwiftUI

struct CodeTextView: View {
    let lines: [String]
    let tokens: [LineTokens]
    let wraps: Bool

    private let renderer = HighlightedTextRenderer()

    var body: some View {
        Group {
            if wraps {
                ScrollView(.vertical) { wrapped }
            } else {
                GeometryReader { proxy in
                    ScrollView(.vertical) { unwrapped(width: proxy.size.width) }
                }
            }
        }
        .background(Theme.Code.canvas)
        .accessibilityIdentifier(UIIdentifier.File.codeContent)
    }

    private var wrapped: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                HStack(alignment: .top, spacing: Theme.Space.step2) {
                    number(index + 1)
                    text(line, at: index)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.trailing, Theme.Space.screenMargin)
            }
        }
        .padding(.vertical, Theme.Space.step3)
    }

    private func unwrapped(width: CGFloat) -> some View {
        HStack(alignment: .top, spacing: Theme.Space.step2) {
            LazyVStack(alignment: .trailing, spacing: 0) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, _ in
                    number(index + 1).frame(height: rowHeight)
                }
            }
            .frame(width: gutterWidth)
            ScrollView(.horizontal, showsIndicators: true) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        text(line, at: index)
                            .fixedSize(horizontal: true, vertical: false)
                            .frame(height: rowHeight, alignment: .leading)
                    }
                }
                .frame(width: contentWidth, alignment: .leading)
                .padding(.trailing, Theme.Space.screenMargin)
            }
            .frame(width: max(0, width - gutterWidth - Theme.Space.step2))
        }
        .padding(.vertical, Theme.Space.step3)
    }

    private var gutterWidth: CGFloat {
        CGFloat(max(2, String(lines.count).count)) * advance + Theme.Space.step3
    }

    private var rowHeight: CGFloat { CodeFont.lineHeight(size: CodeFont.defaultSize) }

    private var advance: CGFloat { CodeFont.characterWidth(size: CodeFont.defaultSize) }

    private var contentWidth: CGFloat {
        CGFloat(lines.reduce(0) { max($0, $1.count) }) * advance
    }

    private func number(_ value: Int) -> some View {
        Text(String(value))
            .font(Theme.code())
            .foregroundStyle(Theme.Code.lineNumber)
            .frame(width: gutterWidth, alignment: .trailing)
    }

    private func text(_ line: String, at index: Int) -> some View {
        Text(
            renderer.attributed(
                line: line,
                tokens: tokens.indices.contains(index) ? tokens[index] : nil
            )
        )
        .textSelection(.enabled)
    }
}
#endif
