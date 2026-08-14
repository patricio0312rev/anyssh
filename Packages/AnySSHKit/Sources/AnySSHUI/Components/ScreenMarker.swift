import AnySSHCore
import SwiftUI

public struct ScreenMarker: View {
    private let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public init(state: ErrorState) {
        self.init(identifier: state.accessibilityIdentifier)
    }

    public var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .accessibilityIdentifier(identifier)
    }
}

#Preview("ScreenMarker") {
    ThemedRoot {
        VStack(spacing: Theme.Space.step2) {
            ScreenMarker(identifier: "preview.screen")
            PrimaryTitle("A screen that names itself without claiming its children")
        }
        .padding(Theme.Space.screenMargin)
    }
}
