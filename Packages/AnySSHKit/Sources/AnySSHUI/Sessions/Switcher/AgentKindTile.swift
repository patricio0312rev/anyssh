import AnySSHCore
import SwiftUI

struct AgentKindTile: View {
    let kind: AgentKind

    var body: some View {
        if AgentMarkCatalog.hasMark(for: kind.id) {
            RowIconTile(
                asset: AgentMarkCatalog.assetName(for: kind.id),
                label: kind.name,
                tint: Theme.text.primary,
                fillsTile: AgentMarkCatalog.fillsTile(kind.id)
            )
        } else {
            RowIconTile(monogram: kind.monogram, label: kind.name)
        }
    }
}
