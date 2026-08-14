import AnySSHCore
import Foundation
import Testing

@testable import TerminalEmulator

private actor RecordingScheduler: NotificationScheduler {
    private(set) var requests: [JobAlertRequest] = []

    func schedule(_ request: JobAlertRequest) async {
        requests.append(request)
    }
}

@Suite struct OSC9Tests {
    private static let sessionID = SessionID(rawValue: "notify-1")

    @Test func osc9BelFormSchedulesExactlyOneRequest() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)

        let outcome = engine.feed(Array("\u{1b}]9;Backup finished\u{7}".utf8)[...])

        #expect(outcome == .alert(JobFinishAlert(title: "Backup finished")))
        let requests = await Self.settled(scheduler, atLeast: 1)
        #expect(
            requests
                == [
                    JobAlertRequest(
                        alert: JobFinishAlert(title: "Backup finished"),
                        sessionID: Self.sessionID
                    )
                ]
        )
    }

    @Test func osc9AfterEarlierEscapeSequencesStillSchedules() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)

        let outcome = engine.feed(
            Array("\u{1b}[2J\u{1b}]9;Backup finished\u{7}".utf8)[...]
        )

        #expect(outcome == .alert(JobFinishAlert(title: "Backup finished")))
        let requests = await Self.settled(scheduler, atLeast: 1)
        #expect(requests.first?.alert.title == "Backup finished")
    }

    @Test func osc9MultibytePayloadKeepsItsDecodedTitle() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)

        let outcome = engine.feed(Array("\u{1b}]9;Terminó la copia\u{7}".utf8)[...])

        #expect(outcome == .alert(JobFinishAlert(title: "Terminó la copia")))
        let requests = await Self.settled(scheduler, atLeast: 1)
        #expect(requests.first?.alert.title == "Terminó la copia")
    }

    @Test func osc777NotifyFormSchedulesOneRequestWithTitleAndBody() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)

        let outcome = engine.feed(
            Array("\u{1b}]777;notify;Sync done;Backups synced\u{7}".utf8)[...]
        )

        #expect(outcome == .alert(JobFinishAlert(title: "Sync done", body: "Backups synced")))
        let requests = await Self.settled(scheduler, atLeast: 1)
        #expect(requests.first?.alert == JobFinishAlert(title: "Sync done", body: "Backups synced"))
    }

    @Test func osc777WithoutNotifyPrefixIsNotAJobAlert() {
        let engine = OSCJobAlertEngine(
            sessionID: Self.sessionID,
            scheduler: RecordingScheduler()
        )

        let outcome = engine.feed(
            Array("\u{1b}]777;progress;42\u{7}".utf8)[...]
        )

        #expect(outcome == .notJobAlert)
    }

    @Test func oversizedPayloadIsRefusedWithTheRegistryCopy() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)
        let payload = String(repeating: "x", count: OSCJobAlertEngine.maxPayloadBytes + 1)

        let outcome = engine.feed(Array("\u{1b}]9;\(payload)\u{7}".utf8)[...])

        guard case .refused(let refusal) = outcome else {
            Issue.record("expected a refusal, got \(outcome)")
            return
        }
        #expect(refusal == .oversizedPayload)
        #expect(refusal.errorState.copy == ErrorState.notifications(.alertTooLarge).copy)
        let requests = await Self.settled(scheduler, atLeast: 0)
        #expect(requests.isEmpty)
    }

    @Test func osc133FailedExitIsAFailureFlavouredAlert() async {
        let scheduler = RecordingScheduler()
        let engine = OSCJobAlertEngine(sessionID: Self.sessionID, scheduler: scheduler)
        let copy = ErrorState.notifications(.jobFailed).copy

        let outcome = engine.feed(Array("\u{1b}]133;D;1\u{7}".utf8)[...])

        guard case .alert(let alert) = outcome else {
            Issue.record("expected an alert, got \(outcome)")
            return
        }
        #expect(alert.exitStatus == 1)
        #expect(alert.isFailure)
        #expect(alert.title == copy.title)
        #expect(alert.body == copy.body)
        let requests = await Self.settled(scheduler, atLeast: 1)
        #expect(requests.first?.alert.exitStatus == 1)
    }

    @Test func osc133ZeroExitIsASuccessAlert() async {
        let engine = OSCJobAlertEngine(
            sessionID: Self.sessionID,
            scheduler: RecordingScheduler()
        )

        let outcome = engine.feed(Array("\u{1b}]133;D;0\u{7}".utf8)[...])

        guard case .alert(let alert) = outcome else {
            Issue.record("expected an alert, got \(outcome)")
            return
        }
        #expect(alert.exitStatus == 0)
        #expect(!alert.isFailure)
        #expect(alert.title == "Job finished")
    }

    @Test func osc52StaysOutOfTheJobAlertEngine() async {
        let engine = OSCJobAlertEngine(
            sessionID: Self.sessionID,
            scheduler: RecordingScheduler()
        )
        let pasteboard = RecordingPasteboard()
        let encoded = Data("copied text".utf8).base64EncodedString()

        let outcome = engine.feed(Array("\u{1b}]52;c;\(encoded)\u{7}".utf8)[...])

        #expect(outcome == .notJobAlert)
        let pasteOutcome = OSC52Inbound.handle(
            sequence: Array("\u{1b}]52;c;\(encoded)\u{7}".utf8)[...],
            pasteboard: pasteboard
        )
        #expect(pasteOutcome == .wrote("copied text"))
        #expect(pasteboard.writes == ["copied text"])
    }

    private static func settled(
        _ scheduler: RecordingScheduler,
        atLeast count: Int
    ) async -> [JobAlertRequest] {
        for _ in 0..<5_000 {
            let requests = await scheduler.requests
            if requests.count >= count { return requests }
            await Task.yield()
        }
        return await scheduler.requests
    }
}
