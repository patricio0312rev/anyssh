#if canImport(UIKit)
import SwiftUI
import Testing

@testable import AnySSHUI

@Suite @MainActor struct ChromeSnapshotTests {
    @Test func screenHeaderWithAndWithoutActions() {
        ComponentSnapshot.assert(
            VStack(spacing: Theme.Space.step5) {
                ScreenHeader("Hosts") {
                    IconButton(systemImage: "gearshape", label: "Settings", surface: .inline) {}
                    IconButton(systemImage: "plus", label: "Add host", surface: .inline) {}
                }
                ScreenHeader("Settings")
                Spacer()
            },
            named: "screenHeader",
            height: 260
        )
    }

    @Test func surfaceCardSelection() {
        ComponentSnapshot.assert(
            VStack(spacing: Theme.Space.rowGap) {
                SurfaceCard { PrimaryTitle("Plain card") }
                SurfaceCard(isSelected: true) { PrimaryTitle("Selected card") }
            }
            .padding(Theme.Space.screenMargin),
            named: "surfaceCard",
            height: 180
        )
    }

    @Test func loadingViewVariants() {
        ComponentSnapshot.assert(
            VStack(spacing: Theme.Space.step5) {
                LoadingView(.inline)
                LoadingView(.screen(label: "Loading hosts"))
            },
            named: "loadingView",
            height: 240
        )
    }

    @Test func sectionLabelAndSettingsRow() {
        ComponentSnapshot.assert(
            VStack(alignment: .leading, spacing: 0) {
                SectionLabel("General")
                SurfaceCard {
                    VStack(spacing: Theme.Space.rowGap) {
                        SettingsRow(
                            title: "Gestures",
                            subtitle: "What a swipe sends to the terminal",
                            systemImage: "hand.draw"
                        )
                        SettingsRow(
                            title: "Snippets",
                            subtitle: "Commands you send often",
                            systemImage: "text.append"
                        )
                    }
                }
                SectionLabel("About")
                Spacer()
            }
            .padding(Theme.Space.screenMargin),
            named: "settingsCluster",
            height: 300
        )
    }

    @Test func copyableRowIdleAndMonospaced() {
        ComponentSnapshot.assert(
            SurfaceCard {
                VStack(spacing: Theme.Space.rowGap) {
                    CopyableRow(
                        label: "Commit",
                        value: "8f3c1d9a2b4e6f70a1c3d5e7f9012345",
                        monospaced: true,
                        accessibilityIdentifier: "snapshot.copy.sha"
                    ) { _ in }
                    CopyableRow(
                        label: "Author",
                        value: "Ada Lovelace",
                        accessibilityIdentifier: "snapshot.copy.author"
                    ) { _ in }
                }
            }
            .padding(Theme.Space.screenMargin),
            named: "copyableRow",
            height: 200
        )
    }
}
#endif
