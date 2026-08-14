import AnySSHCore
import AnySSHMocks
import AnySSHUI
import SwiftUI

struct SessionsPanelsScenario: View {
    var body: some View {
        VStack(spacing: 0) {
            Theme.Code.canvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            ShortcutPanelsView(
                kind: .tmux,
                capabilities: CapabilityFixture.everythingPresent.capabilities,
                bindings: MuxKeyBindings(prefix: "C-b", chords: [:]),
                directory: ScenarioStoreLocation.panels
            )
        }
        .ignoresSafeArea(edges: .top)
    }
}
