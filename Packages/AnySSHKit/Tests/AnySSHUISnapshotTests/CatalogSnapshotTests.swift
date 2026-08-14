#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct CatalogSnapshotTests {
    @Test func rowLayouts() {
        ComponentSnapshot.assert(
            VStack(spacing: Theme.Space.rowGap) {
                SurfaceCard {
                    CatalogRow(
                        title: "build-box",
                        subtitle: "deploy@build.internal",
                        detail: "Last connected 4 minutes ago",
                        accessibilityIdentifier: "snapshot.row.list"
                    )
                }
                SurfaceCard {
                    CatalogRow(
                        title: "fix: resolve token refresh race",
                        subtitle: "8f3c1d9",
                        subtitleMonospaced: true,
                        detail: "Ada Lovelace",
                        layout: .stacked,
                        accessibilityIdentifier: "snapshot.row.stacked"
                    )
                }
            }
            .padding(Theme.Space.screenMargin),
            named: "catalogRow-layouts",
            height: 260
        )
    }

    @Test func rowWithLeadingAndTrailing() {
        ComponentSnapshot.assert(
            SurfaceCard {
                CatalogRow(
                    title: "edge-01",
                    subtitle: "root@10.0.0.7",
                    accessibilityIdentifier: "snapshot.row.decorated"
                ) {
                    RowIconTile(systemImage: "server.rack", label: "Host")
                } trailing: {
                    Image(systemName: "chevron.right").foregroundStyle(Theme.text.tertiary)
                } footer: {
                    EmptyView()
                }
            }
            .padding(Theme.Space.screenMargin),
            named: "catalogRow-decorated",
            height: 160
        )
    }

    @Test func listSurfaceWithSelection() {
        ComponentSnapshot.assert(
            List {
                CatalogRow(
                    title: "build-box",
                    subtitle: "deploy@build.internal",
                    accessibilityIdentifier: "snapshot.list.row1"
                )
                .catalogRowChrome()
                CatalogRow(
                    title: "edge-01",
                    subtitle: "root@10.0.0.7",
                    accessibilityIdentifier: "snapshot.list.row2"
                )
                .catalogRowChrome(selected: true)
                CatalogRow(
                    title: "db-primary",
                    subtitle: "postgres@10.0.0.9",
                    accessibilityIdentifier: "snapshot.list.row3"
                )
                .catalogRowChrome()
            }
            .catalogListSurface(),
            named: "catalogList",
            height: 340
        )
    }

    @Test func iconTileMarks() {
        ComponentSnapshot.assert(
            HStack(spacing: Theme.Space.step3) {
                RowIconTile(systemImage: "server.rack", label: "Host")
                RowIconTile(systemImage: "folder", label: "Folder")
                RowIconTile(monogram: "A", label: "Agent")
                RowIconTile(monogram: "tm", label: "tmux")
            },
            named: "rowIconTile",
            height: 120
        )
    }
}
#endif
