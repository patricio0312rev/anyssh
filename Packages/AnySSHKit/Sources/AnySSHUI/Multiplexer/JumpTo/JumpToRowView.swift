import AnySSHCore
import SwiftUI

struct JumpToRowView: View {
    let row: JumpRow
    let isJumping: Bool
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
                    trailing: { accessory },
                    footer: { EmptyView() }
                )
            }
            .buttonStyle(.plain)
            JumpToStatusDot(row: row)
        }
    }

    @ViewBuilder
    private var accessory: some View {
        if isJumping {
            LoadingView(.inline)
                .accessibilityIdentifier(JumpToIdentifier.jumping(row.id.rawValue))
        } else if row.isActive {
            Text(MuxNavigationCopy.active)
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
        row.status.dot(accessibilityIdentifier: JumpToIdentifier.status(row.id.rawValue))
    }
}

extension JumpAgentStatus {
    func dot(accessibilityIdentifier: String) -> StatusDot? {
        guard let color else { return nil }
        return StatusDot(
            color: color,
            label: "Agent status",
            value: valueText,
            accessibilityIdentifier: accessibilityIdentifier
        )
    }

    private var color: Color? {
        switch self {
        case .waiting(let value): value == "blocked" ? Theme.status.attention : Theme.status.busy
        case .finished: Theme.status.online
        case .unknown: nil
        }
    }
}
