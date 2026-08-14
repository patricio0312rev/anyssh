import AnySSHCore
import AnySSHUI
import SwiftUI

struct SettingsScenarioView: View {
    let scenario: SettingsScenario

    var body: some View {
        surface.tint(Theme.accent)
    }

    @ViewBuilder
    private var surface: some View {
        switch scenario {
        case .sheet:
            SettingsSheetScenario()
        case .gestures:
            pushed { GestureSettingsView(directory: ScenarioStoreLocation.gestures) }
        case .snippets:
            pushed { SnippetLibraryView(store: ScenarioStoreLocation.seededSnippets()) }
        case .snippetsEmpty:
            pushed { SnippetLibraryView(store: ScenarioStoreLocation.emptySnippets()) }
        case .privacy:
            pushed { PrivacyPolicyView() }
        case .about:
            pushed { AboutView(version: AppRelease.version, build: AppRelease.build) }
        case .notice:
            pushed { NoticeDetailView(notice: ThirdPartyNotices.all.sorted()[0]) }
        }
    }

    private func pushed<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationStack { content() }
    }
}

private struct SettingsSheetScenario: View {
    @State private var isPresented = true

    var body: some View {
        Theme.surface.base
            .ignoresSafeArea()
            .sheet(isPresented: $isPresented) {
                SettingsView(
                    layoutDirectory: ScenarioStoreLocation.gestures,
                    snippets: ScenarioStoreLocation.seededSnippets()
                )
                .presentationDragIndicator(.visible)
            }
    }
}
