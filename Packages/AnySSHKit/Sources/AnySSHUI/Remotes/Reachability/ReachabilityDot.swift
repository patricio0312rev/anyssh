import AnySSHCore
import SwiftUI

extension StatusDot {
    public init(reachability: ReachabilityPresentation, remoteID: String = "preview") {
        self.init(
            color: Self.color(for: reachability),
            label: "Reachability",
            value: reachability.rawValue,
            accessibilityIdentifier: UIIdentifier.Remote.reachability(remoteID)
        )
    }

    private static func color(for reachability: ReachabilityPresentation) -> Color {
        switch reachability {
        case .checking: Theme.status.busy
        case .reachable: Theme.status.online
        case .unreachable: Theme.status.offline
        case .unknown: Theme.status.attention
        }
    }
}

#Preview("ReachabilityDot") {
    ThemedRoot {
        HStack(spacing: Theme.Space.step4) {
            ForEach(ReachabilityPresentation.allCases, id: \.self) { reachability in
                StatusDot(reachability: reachability, remoteID: reachability.rawValue)
            }
        }
        .padding(Theme.Space.screenMargin)
    }
}
