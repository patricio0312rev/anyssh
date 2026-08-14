import AnySSHCore
import AnySSHUI
import SwiftUI

struct ErrorStateScenarioView: View {
    let state: ErrorState
    let secrets: any SecretStore

    @State private var resolved: ErrorState?

    var body: some View {
        ErrorStateView(state: resolved ?? state, recover: {}, dismiss: {})
            .task { await unlock() }
    }

    private func unlock() async {
        guard case .secrets = state else { return }
        let reference = SecretReference(
            remoteID: RemoteID(rawValue: "scenario"),
            kind: .privateKey
        )
        do {
            _ = try await secrets.secret(reference)
        } catch let error as SecretStoreError {
            resolved = .secrets(error.state)
        } catch {
            resolved = .secrets(.keychainReadDenied)
        }
    }
}
