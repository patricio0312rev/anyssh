import AnySSHCore
import AnySSHMocks
import Foundation
import Testing

@testable import AnySSHUI

@MainActor
@Suite struct JobAlertDeliveryTests {
    private static let sessionID = SessionID(rawValue: "session-a")

    @Test func aForegroundAlertRaisesABannerAndRequestsNoSystemNotification() async {
        let recorder = Recorder()
        let system = RecordingNotificationScheduler()
        let delivery = Self.delivery(system: system, isForeground: true, recorder: recorder)

        await delivery.schedule(Self.request(title: "Backup finished"))

        #expect(recorder.banners.map(\.title) == ["Backup finished"])
        let scheduled = await system.requests
        #expect(recorder.systemRequests.isEmpty)
        #expect(scheduled.isEmpty)
    }

    @Test func aBackgroundAlertReachesTheSystemScheduler() async {
        let recorder = Recorder()
        let system = RecordingNotificationScheduler()
        let delivery = Self.delivery(system: system, isForeground: false, recorder: recorder)

        await delivery.schedule(Self.request(title: "Backup finished"))

        let scheduled = await system.requests
        #expect(recorder.banners.isEmpty)
        #expect(recorder.systemRequests.count == 1)
        #expect(scheduled.map(\.alert.title) == ["Backup finished"])
    }

    @Test func quietingDropsASuccessButNeverAFailure() async {
        let recorder = Recorder()
        let system = RecordingNotificationScheduler()
        let delivery = Self.delivery(
            system: system,
            isForeground: true,
            recorder: recorder,
            suppressesSuccess: true
        )

        await delivery.schedule(Self.request(title: "Backup finished"))
        await delivery.schedule(Self.request(title: "Deploy failed", exitStatus: 1))

        #expect(recorder.banners.map(\.title) == ["Deploy failed"])
    }

    @Test func aFailureBannerCarriesTheErrorSeverity() async {
        let recorder = Recorder()
        let delivery = Self.delivery(
            system: RecordingNotificationScheduler(),
            isForeground: true,
            recorder: recorder
        )

        await delivery.schedule(Self.request(title: "Deploy failed", exitStatus: 1))

        #expect(recorder.banners.map(\.severity) == [.error])
        #expect(recorder.banners.first?.accessibilityIdentifier == UIIdentifier.JobAlerts.banner)
    }

    @MainActor
    private final class Recorder {
        var banners: [StatusToast] = []
        var systemRequests: [JobAlertRequest] = []
    }

    private static func delivery(
        system: any NotificationScheduler,
        isForeground: Bool,
        recorder: Recorder,
        suppressesSuccess: Bool = false
    ) -> JobAlertDelivery {
        JobAlertDelivery(
            system: system,
            settings: JobAlertSettings(suppressesSuccess: suppressesSuccess),
            isForeground: { isForeground },
            presentBanner: { recorder.banners.append($0) },
            onSystemRequest: { recorder.systemRequests.append($0) }
        )
    }

    private static func request(title: String, exitStatus: Int? = nil) -> JobAlertRequest {
        JobAlertRequest(
            alert: JobFinishAlert(title: title, exitStatus: exitStatus),
            sessionID: sessionID
        )
    }
}
