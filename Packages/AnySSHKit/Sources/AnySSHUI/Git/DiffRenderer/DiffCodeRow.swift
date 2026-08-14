import SwiftUI

struct DiffCodeRow: View {
    let row: DiffRow
    let gutter: DiffGutter
    let softWrap: Bool
    let fontSize: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            if gutter.showsOldNumbers { number(row.oldLineNumber) }
            if gutter.showsNewNumbers { number(row.newLineNumber) }
            Text(marker)
                .font(Theme.code(size: fontSize))
                .frame(width: DiffMetrics.markerColumn)
                .foregroundStyle(markerColor)
            Text(row.text.isEmpty ? " " : row.text)
                .font(Theme.code(size: fontSize))
                .foregroundStyle(Theme.Code.foreground)
                .lineLimit(softWrap ? nil : 1)
                .fixedSize(horizontal: !softWrap, vertical: false)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Theme.Space.step2)
        .padding(.vertical, DiffMetrics.rowLeading)
        .background(background)
        .accessibilityIdentifier(UIIdentifier.Diff.row(row.id))
    }

    private func number(_ value: Int?) -> some View {
        Text(value.map(String.init) ?? "")
            .font(Theme.code(size: fontSize))
            .frame(width: DiffMetrics.lineNumberColumn, alignment: .trailing)
            .foregroundStyle(Theme.Code.lineNumber)
    }

    private var marker: String {
        switch row.kind {
        case .addition: "+"
        case .deletion: "-"
        default: " "
        }
    }

    private var markerColor: Color {
        switch row.kind {
        case .addition: Theme.Code.Diff.added
        case .deletion: Theme.Code.Diff.removed
        default: Theme.Code.lineNumber
        }
    }

    private var background: Color {
        switch row.kind {
        case .addition: Theme.Code.Diff.addedFill
        case .deletion: Theme.Code.Diff.removedFill
        default: .clear
        }
    }
}

#Preview("DiffCodeRow") {
    let rows = [
        DiffRow(
            id: "line-0-0",
            kind: .context,
            text: "func load() async {",
            oldLineNumber: 41,
            newLineNumber: 41
        ),
        DiffRow(id: "line-0-1", kind: .deletion, text: "    state = .idle", oldLineNumber: 42),
        DiffRow(id: "line-0-2", kind: .addition, text: "    state = .loading", newLineNumber: 42),
    ]
    let added = [DiffRow(id: "line-1-0", kind: .addition, text: "# New file", newLineNumber: 1)]
    return ThemedRoot {
        VStack(spacing: 0) {
            ForEach(rows) { row in
                DiffCodeRow(
                    row: row,
                    gutter: DiffGutter(rows: rows),
                    softWrap: true,
                    fontSize: DiffFontScale.defaultSize
                )
            }
            ForEach(added) { row in
                DiffCodeRow(
                    row: row,
                    gutter: DiffGutter(rows: added),
                    softWrap: true,
                    fontSize: DiffFontScale.defaultSize
                )
            }
        }
        .background(Theme.Code.canvas)
    }
}
