import AnySSHCore
import SwiftUI

struct SessionSwitcherRow: View {
    enum Style { case list, grid }

    let record: SessionRecord
    let hostAddress: String
    let remoteName: String?
    let agentKind: AgentKind?
    let uptime: String
    let isActive: Bool
    var style: Style = .list

    var body: some View {
        CatalogRow(
            title: record.title,
            subtitle: subtitle,
            subtitleMonospaced: true,
            detail: detail,
            titleLineLimit: 1,
            layout: style == .grid ? .stacked : .list,
            accessibilityIdentifier: SessionSwitcherIdentifier.row(record.id.rawValue),
            leading: { tile },
            trailing: { EmptyView() },
            footer: { EmptyView() }
        )
    }

    private var subtitle: String {
        let name = remoteName ?? hostAddress
        return record.title == name ? "" : name
    }

    @ViewBuilder
    private var tile: some View {
        if let agentKind {
            if AgentMarkCatalog.hasMark(for: agentKind.id) {
                RowIconTile(
                    asset: AgentMarkCatalog.assetName(for: agentKind.id),
                    label: agentKind.name,
                    tint: Theme.text.primary,
                    fillsTile: AgentMarkCatalog.fillsTile(agentKind.id)
                )
            } else {
                RowIconTile(monogram: agentKind.monogram, label: agentKind.name)
            }
        } else {
            RowIconTile(systemImage: "terminal", label: "Shell")
        }
    }

    private var detail: String? {
        [record.state.label, uptime, isActive ? "Active" : nil]
            .compactMap { $0 }
            .joined(separator: Theme.metaSeparator)
    }
}
