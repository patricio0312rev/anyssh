import AnySSHCore
import SwiftUI

struct JumpToRowView: View {
    let row: JumpRow
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: Theme.Space.step3) {
            Button(action: onTap) {
                CatalogRow(
                    title: row.title,
                    subtitle: subtitle,
                    subtitleMonospaced: true,
                    accessibilityIdentifier: JumpToIdentifier.row(row.id.rawValue),
                    leading: { EmptyView() },
                    trailing: { activeBadge },
                    footer: { EmptyView() }
                )
            }
            .buttonStyle(.plain)
            JumpToStatusDot(row: row)
        }
    }

    @ViewBuilder
    private var activeBadge: some View {
        if row.isActive {
            Text("Active")
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
        }
    }

    private var subtitle: String {
        row.paneCount == 1 ? "1 pane" : "\(row.paneCount) panes"
    }
}

struct JumpToStatusDot: View {
    let row: JumpRow

    var body: some View {
        if let color = statusColor {
            StatusDot(
                color: color,
                label: "Agent status",
                value: row.status.valueText,
                accessibilityIdentifier: JumpToIdentifier.status(row.id.rawValue)
            )
        }
    }

    private var statusColor: Color? {
        switch row.status {
        case .waiting(let value): value == "blocked" ? Theme.status.attention : Theme.status.busy
        case .finished: Theme.status.online
        case .unknown: nil
        }
    }
}
