import AnySSHMocks
import AnySSHUI
import SwiftUI

struct GitScenarioView: View {
    let scenario: GitScenario

    var body: some View {
        NavigationStack {
            surface
        }
        .tint(Theme.accent)
    }

    @ViewBuilder
    private var surface: some View {
        switch scenario {
        case .changes:
            ChangesListView(location: GitFixtures.location, git: MockGitService(.dirty))
                .navigationTitle("Changes")
        case .changesExpanded:
            ChangesListView(
                location: GitFixtures.location,
                git: MockGitService(.dirty),
                expandsFirstFile: true
            )
            .navigationTitle("Changes")
        case .changesNewFile:
            ChangesListView(
                location: GitFixtures.location,
                git: MockGitService(.newFile),
                expandsFirstFile: true
            )
            .navigationTitle("Changes")
        case .changesClean:
            ChangesListView(location: GitFixtures.location, git: MockGitService(.clean))
                .navigationTitle("Changes")
        case .history:
            HistoryView(service: MockGitService(.dirty), repository: GitFixtures.repository)
        case .historyEmpty:
            HistoryView(service: MockGitService(.emptyHistory), repository: GitFixtures.repository)
        case .historyDetail:
            HistoryView(
                service: MockGitService(.dirty),
                repository: GitFixtures.repository,
                selected: GitFixtures.commits[2]
            )
        case .diff:
            DiffDetailView(
                file: GitFixtures.staged[0],
                repository: GitFixtures.repository,
                git: MockGitService(.dirty)
            )
        }
    }
}
