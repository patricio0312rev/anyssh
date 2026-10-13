import AnySSHCore
import SwiftUI

struct AgentsMenuRow: View {
    let entry: MuxAgentEntry
    let isJumping: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CatalogRow(
                title: entry.title,
                subtitle: entry.detail,
                detail: AgentsMenuCopy.location(of: entry),
                detailStatus: status.dot(
                    accessibilityIdentifier: AgentsMenuIdentifier.status(entry.id.rawValue)
                ),
                accessibilityIdentifier: AgentsMenuIdentifier.row(entry.id.rawValue),
                leading: { tile },
                trailing: { accessory },
                footer: { EmptyView() }
            )
        }
        .buttonStyle(.plain)
    }

    private var status: JumpAgentStatus {
        entry.status.map(JumpAgentStatus.init(rawValue:)) ?? .unknown
    }

    @ViewBuilder
    private var tile: some View {
        if let kind = entry.kind {
            AgentKindTile(kind: kind)
        } else {
            RowIconTile(monogram: String(entry.title.prefix(1)).uppercased(), label: entry.title)
        }
    }

    @ViewBuilder
    private var accessory: some View {
        if isJumping {
            LoadingView(.inline)
                .accessibilityIdentifier(AgentsMenuIdentifier.jumping(entry.id.rawValue))
        } else if entry.isActive {
            Text(MuxNavigationCopy.active)
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
        }
    }
}
