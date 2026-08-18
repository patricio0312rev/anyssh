#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SettingsView: View {
    private let layoutDirectory: URL
    private let snippets: SnippetStore
    private let titleStore: SessionTitlePreferenceStore

    @Environment(\.dismiss) private var dismiss

    public init(
        layoutDirectory: URL,
        snippets: SnippetStore = .applicationSupport(),
        titleStore: SessionTitlePreferenceStore = .shared
    ) {
        self.layoutDirectory = layoutDirectory
        self.snippets = snippets
        self.titleStore = titleStore
    }

    public var body: some View {
        SheetScaffold(
            "Settings",
            closeIdentifier: UIIdentifier.Settings.close,
            onClose: { dismiss() }
        ) {
            List {
                terminal
                legal
            }
            .catalogListSurface()
            .accessibilityIdentifier(UIIdentifier.Settings.screen)
        }
    }

    private var terminal: some View {
        Section {
            NavigationLink {
                GestureSettingsView(directory: layoutDirectory)
            } label: {
                SettingsRow(
                    title: "Gestures",
                    subtitle: "What a swipe does",
                    systemImage: "hand.draw"
                )
            }
            .accessibilityIdentifier(UIIdentifier.Settings.gestures)
            .catalogRowChrome()
            NavigationLink {
                SessionTitleSettingsView(store: titleStore)
            } label: {
                SettingsRow(
                    title: "Session title",
                    subtitle: titleStore.mode.title,
                    systemImage: "textformat"
                )
            }
            .accessibilityIdentifier(UIIdentifier.Settings.title)
            .catalogRowChrome()
            NavigationLink {
                SnippetLibraryView(store: snippets)
            } label: {
                SettingsRow(
                    title: "Saved commands",
                    subtitle: "Text you insert rather than retype",
                    systemImage: "text.badge.plus"
                )
            }
            .accessibilityIdentifier(UIIdentifier.Settings.snippets)
            .catalogRowChrome()
        } header: {
            SectionLabel("Terminal")
        }
    }

    private var legal: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                SettingsRow(
                    title: "Privacy",
                    subtitle: "What leaves this device",
                    systemImage: "lock.shield"
                )
            }
            .accessibilityIdentifier(UIIdentifier.Settings.privacy)
            .catalogRowChrome()
            NavigationLink {
                AboutView(version: AppRelease.version, build: AppRelease.build)
            } label: {
                SettingsRow(
                    title: "About",
                    subtitle: "Version and licences",
                    systemImage: "info.circle"
                )
            }
            .accessibilityIdentifier(UIIdentifier.Settings.about)
            .catalogRowChrome()
        } header: {
            SectionLabel("Legal")
        }
    }
}

#Preview("SettingsView") {
    ThemedRoot {
        SettingsView(layoutDirectory: URL.temporaryDirectory.appending(path: "settings-preview"))
    }
}
#endif
