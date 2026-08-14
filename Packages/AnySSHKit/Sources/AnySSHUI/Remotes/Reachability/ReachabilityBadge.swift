import AnySSHCore
import SwiftUI

public struct ReachabilityBadge: View {
    public let presentation: ReachabilityPresentation
    public let remoteID: String

    public init(presentation: ReachabilityPresentation, remoteID: String = "preview") {
        self.presentation = presentation
        self.remoteID = remoteID
    }

    public init(_ reachability: Reachability, remoteID: String = "preview") {
        self.presentation = ReachabilityPresentation(reachability)
        self.remoteID = remoteID
    }

    public var body: some View {
        Image(systemName: presentation.symbolName)
            .font(Theme.Text.body)
            .foregroundStyle(color)
            .accessibilityLabel(presentation.accessibilityLabel)
            .accessibilityIdentifier(UIIdentifier.Remote.reachability(remoteID))
    }

    private var color: Color {
        switch presentation {
        case .checking: Theme.status.busy
        case .reachable: Theme.status.online
        case .unreachable: Theme.status.offline
        case .unknown: Theme.status.attention
        }
    }
}

#Preview("ReachabilityBadge") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step4) {
            ForEach(ReachabilityPresentation.allCases, id: \.self) { presentation in
                ReachabilityBadge(presentation: presentation, remoteID: presentation.rawValue)
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
