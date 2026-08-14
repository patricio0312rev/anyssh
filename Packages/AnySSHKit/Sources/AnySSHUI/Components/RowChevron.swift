import SwiftUI

public struct RowChevron: View {
    public init() {}

    public var body: some View {
        Image(systemName: "chevron.right")
            .font(Theme.Text.caption.weight(.semibold))
            .foregroundStyle(Theme.text.tertiary)
    }
}

#Preview("RowChevron") {
    ThemedRoot {
        SurfaceCard {
            CatalogRow(
                title: "build-box",
                subtitle: "deploy@build.internal",
                accessibilityIdentifier: "preview.chevron.row"
            ) {
                RowIconTile(systemImage: "server.rack", label: "Host")
            } trailing: {
                RowChevron()
            } footer: {
                EmptyView()
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
