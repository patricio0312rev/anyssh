#if canImport(UIKit)
import AnySSHCore
import SafariServices
import SwiftUI
import UIKit

@MainActor
public final class TerminalLinkOpener {
    public var presenting: () -> UIViewController?

    public init(presenting: @escaping () -> UIViewController?) {
        self.presenting = presenting
    }

    public func open(_ url: URL) {
        guard let host = presenting() else { return }
        host.present(SFSafariViewController(url: url), animated: true)
    }

    public func refuse(_ state: ErrorState) {
        guard let host = presenting() else { return }
        host.present(UIHostingController(rootView: ErrorStateView(state: state)), animated: true)
    }
}
#endif
