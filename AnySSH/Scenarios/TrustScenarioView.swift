import AnySSHCore
import AnySSHMocks
import AnySSHUI
import SSHTransport
import SwiftUI

struct TrustScenarioView: View {
    @State private var model: HostKeyTrustModel

    private let status: KnownHostStatus

    init(store: any HostKeyStore, scenario: LaunchScenario) {
        _model = State(
            wrappedValue: HostKeyTrustModel(
                store: store,
                host: HostKeyFixtures.host,
                port: HostKeyFixtures.port
            )
        )
        status =
            switch scenario.hostKeyScenario {
            case .knownAndChanged: .changed(stored: HostKeyFixtures.stored.fingerprint)
            case .knownAndMatching: .matches
            case .unknownHost: .unknown
            }
    }

    var body: some View {
        Color.clear
            .overlay { HostKeyTrustView(model: model) }
            .task {
                _ = await model.ask(HostKeyFixtures.offered, status)
            }
    }
}
