import AnySSHCore
import Foundation

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public final class JobAlertDelivery: NotificationScheduler {
    private let system: any NotificationScheduler
    private let settings: JobAlertSettings
    private let isForeground: () -> Bool
    private let presentBanner: (StatusToast) -> Void
    private let onSystemRequest: (JobAlertRequest) -> Void

    public init(
        system: any NotificationScheduler,
        settings: JobAlertSettings,
        isForeground: @escaping () -> Bool,
        presentBanner: @escaping (StatusToast) -> Void,
        onSystemRequest: @escaping (JobAlertRequest) -> Void
    ) {
        self.system = system
        self.settings = settings
        self.isForeground = isForeground
        self.presentBanner = presentBanner
        self.onSystemRequest = onSystemRequest
    }

    @MainActor
    public func schedule(_ request: JobAlertRequest) async {
        guard !(settings.suppressesSuccess && !request.alert.isFailure) else { return }
        if isForeground() {
            presentBanner(banner(for: request.alert))
        } else {
            onSystemRequest(request)
            await system.schedule(request)
        }
    }

    private func banner(for alert: JobFinishAlert) -> StatusToast {
        StatusToast(
            severity: alert.isFailure ? .error : .attention,
            title: alert.title,
            body: alert.body,
            accessibilityIdentifier: UIIdentifier.JobAlerts.banner
        )
    }

    nonisolated static var defaultForegroundCheck: () -> Bool {
        #if canImport(UIKit)
        { UIApplication.shared.applicationState == .active }
        #else
        { true }
        #endif
    }
}
