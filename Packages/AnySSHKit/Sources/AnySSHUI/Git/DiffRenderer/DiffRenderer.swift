#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct DiffRenderer: View {
    private let model: DiffRowModel
    @State private var wrap = LineWrapPreference.shared
    @State private var fontSize = DiffFontScale.defaultSize

    public init(diff: FileDiff) {
        model = DiffRowModel(diff: diff, expandAll: true)
    }

    public var body: some View {
        rows
            .scrollIndicators(.visible)
            .background(Theme.Code.canvas)
            .overlay(alignment: .bottomTrailing) {
                WrapToggle(wrapsLines: $wrap.wrapsLines)
                    .padding(Theme.Space.step2)
            }
            .gesture(
                MagnifyGesture().onChanged { value in
                    fontSize = DiffFontScale.magnified(by: value.magnification)
                }
            )
            .accessibilityIdentifier(UIIdentifier.Diff.renderer)
    }

    @ViewBuilder
    private var rows: some View {
        if wrap.wrapsLines {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) { ForEach(model.rows) { rowView($0) } }
            }
        } else {
            ScrollView([.vertical, .horizontal]) {
                LazyVStack(alignment: .leading, spacing: 0) { ForEach(model.rows) { rowView($0) } }
                    .frame(width: contentWidth, alignment: .leading)
            }
        }
    }

    private var contentWidth: CGFloat {
        let widest = model.rows.reduce(0) { max($0, $1.text.count) }
        return CGFloat(widest) * CodeFont.characterWidth(size: fontSize) + DiffMetrics.gutterWidth
    }

    @ViewBuilder
    private func rowView(_ row: DiffRow) -> some View {
        if row.kind == .hunk {
            Text(row.text.isEmpty ? "Hunk" : row.text)
                .font(Theme.code(size: fontSize))
                .foregroundStyle(Theme.Code.Diff.hunkHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Theme.Space.step2)
                .padding(.vertical, Theme.Space.step1)
                .background(Theme.Code.Diff.hunkHeaderBackground)
        } else {
            DiffCodeRow(row: row, softWrap: wrap.wrapsLines, fontSize: fontSize)
        }
    }
}
#endif
