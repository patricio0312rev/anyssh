#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct SessionTitleSettingsView: View {
    @Bindable private var store: SessionTitlePreferenceStore

    public init(store: SessionTitlePreferenceStore) {
        _store = Bindable(wrappedValue: store)
    }

    public var body: some View {
        List {
            Section {
                ForEach(SessionTitleDisplayMode.allCases, id: \.self) { mode in
                    Button {
                        store.mode = mode
                    } label: {
                        row(mode)
                    }
                    .buttonStyle(.plain)
                    .catalogRowChrome(selected: store.mode == mode)
                    .accessibilityIdentifier(UIIdentifier.Settings.titleMode(mode.rawValue))
                }
            } header: {
                SectionLabel("Session title")
            } footer: {
                SectionCaption("The session name is the fallback when a source is missing.")
            }
            Section {
                SessionNavbarChrome(
                    title: SessionNavbarTitle.preview(for: store.mode),
                    transportState: .connected
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Space.step2)
                .accessibilityIdentifier(UIIdentifier.Settings.titlePreviewBar)
            } header: {
                SectionLabel("Preview")
            }
        }
        .catalogListSurface()
        .navigationTitle("Session title")
        .accessibilityIdentifier(UIIdentifier.Settings.titleScreen)
    }

    private func row(_ mode: SessionTitleDisplayMode) -> some View {
        CatalogRow(
            title: mode.title,
            subtitle: mode.summary,
            titleLineLimit: 1,
            accessibilityIdentifier: UIIdentifier.Settings.titlePreview(mode.rawValue),
            leading: { EmptyView() },
            trailing: { EmptyView() },
            footer: { EmptyView() }
        )
    }
}

#Preview("SessionTitleSettingsView") {
    ThemedRoot {
        NavigationStack {
            SessionTitleSettingsView(store: SessionTitlePreferenceStore())
        }
    }
}
#endif
