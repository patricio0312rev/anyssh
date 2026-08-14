import AnySSHCore
import SwiftUI

struct RemoteRow: View {
    let remote: Remote
    let reachability: ReachabilityPresentation

    var body: some View {
        CatalogRow(
            title: remote.name,
            subtitle: remote.endpoint,
            subtitleMonospaced: true,
            detail: detail,
            accessibilityIdentifier: UIIdentifier.Remote.row(remote.id.rawValue)
        ) {
            RowIconTile(
                systemImage: remote.deviceType.systemImageName,
                label: remote.deviceType.label
            )
        } trailing: {
            ReachabilityBadge(presentation: reachability, remoteID: remote.id.rawValue)
        } footer: {
            EmptyView()
        }
    }

    private var detail: String {
        [remote.authMethod.label, remote.tag]
            .compactMap { $0 }
            .joined(separator: Theme.metaSeparator)
    }
}

extension AuthMethod {
    public var label: String {
        switch self {
        case .publicKey: "Private key"
        case .password: "Password"
        case .keyboardInteractive: "Verification code"
        }
    }
}

#Preview("RemoteRow") {
    ThemedRoot {
        List {
            RemoteRow(
                remote: Remote(
                    id: RemoteID(rawValue: "preview"),
                    name: "build-box",
                    host: "build.internal",
                    port: 22,
                    username: "deploy",
                    authMethod: .publicKey,
                    tag: "work"
                ),
                reachability: .reachable
            )
            .catalogRowChrome()
        }
        .catalogListSurface()
    }
}
