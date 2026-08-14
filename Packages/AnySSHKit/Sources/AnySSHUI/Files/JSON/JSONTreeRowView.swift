import SwiftUI

struct JSONTreeRowView: View {
    let row: JSONFlatRow

    private static let chevronColumn: CGFloat = 12
    private static let depthIndent: CGFloat = 16

    var body: some View {
        HStack(spacing: Theme.Space.step2) {
            chevron
                .frame(width: Self.chevronColumn)
                .foregroundStyle(Theme.text.tertiary)
            Text(row.key ?? row.summary)
                .font(Theme.code())
                .foregroundStyle(Theme.text.primary)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: Theme.Space.step2)
            if row.key != nil {
                Text(row.summary)
                    .font(Theme.code())
                    .foregroundStyle(Theme.text.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.leading, CGFloat(row.depth) * Self.depthIndent)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(row.expanded ? "expanded" : "collapsed")
        .accessibilityIdentifier(UIIdentifier.File.jsonRow(row.id.uuidString))
    }

    @ViewBuilder
    private var chevron: some View {
        if row.isExpandable {
            Image(systemName: row.expanded ? "chevron.down" : "chevron.right")
                .font(Theme.Text.caption.weight(.semibold))
        }
    }

    private var accessibilityLabel: String {
        guard let key = row.key else { return row.summary }
        return "\(key), \(row.summary)"
    }
}
