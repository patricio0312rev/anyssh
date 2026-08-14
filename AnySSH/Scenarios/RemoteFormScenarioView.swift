import AnySSHCore
import AnySSHUI
import SwiftUI

struct RemoteFormScenarioView: View {
    let environment: AppEnvironment
    let route: RemoteRoute

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                RemoteSheet(
                    route: route,
                    secrets: environment.secretStore,
                    hostKeys: environment.hostKeyStore,
                    save: { _ in },
                    dismiss: {}
                )
            }
    }
}
