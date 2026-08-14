import AnySSHCore
import Foundation

public enum JobAlertRefusal: Equatable, Sendable {
    case oversizedPayload

    public var errorState: ErrorState { ErrorState.notifications(.alertTooLarge) }
}

public enum OSCJobAlertOutcome: Equatable, Sendable {
    case alert(JobFinishAlert)
    case refused(JobAlertRefusal)
    case notJobAlert
}

public struct OSCJobAlertEngine: Sendable {
    public static let maxPayloadBytes = 1024

    public let sessionID: SessionID
    public let scheduler: any NotificationScheduler

    public init(sessionID: SessionID, scheduler: any NotificationScheduler) {
        self.sessionID = sessionID
        self.scheduler = scheduler
    }

    @discardableResult
    public func feed(_ bytes: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        guard let frame = OSCJobAlertFrame.parse(bytes) else { return .notJobAlert }
        return handle(code: frame.code, payload: frame.payload)
    }

    @discardableResult
    public func handle(code: Int, payload: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        guard payload.count <= Self.maxPayloadBytes else { return .refused(.oversizedPayload) }
        let outcome = Self.decode(code: code, payload: payload)
        if case .alert(let alert) = outcome {
            let request = JobAlertRequest(alert: alert, sessionID: sessionID)
            Task { await scheduler.schedule(request) }
        }
        return outcome
    }

    private static func decode(code: Int, payload: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        switch code {
        case 9: decodeOSC9(payload)
        case 777: decodeOSC777(payload)
        case 133: decodeOSC133(payload)
        default: .notJobAlert
        }
    }

    private static func decodeOSC9(_ payload: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        let text = String(decoding: payload, as: UTF8.self)
        guard !text.isEmpty else { return .notJobAlert }
        return .alert(JobFinishAlert(title: text))
    }

    private static func decodeOSC777(_ payload: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        let text = String(decoding: payload, as: UTF8.self)
        let parts = text.split(separator: ";", omittingEmptySubsequences: false)
        guard parts.count >= 3, parts[0] == "notify" else { return .notJobAlert }
        let title = String(parts[1])
        guard !title.isEmpty else { return .notJobAlert }
        let body = parts[2...].joined(separator: ";")
        return .alert(JobFinishAlert(title: title, body: body))
    }

    private static func decodeOSC133(_ payload: ArraySlice<UInt8>) -> OSCJobAlertOutcome {
        let text = String(decoding: payload, as: UTF8.self)
        let parts = text.split(separator: ";", omittingEmptySubsequences: false)
        guard parts.count >= 2, parts[0] == "D", let exit = Int(parts[1]) else {
            return .notJobAlert
        }
        if exit == 0 {
            return .alert(
                JobFinishAlert(title: "Job finished", body: "The command completed.", exitStatus: 0)
            )
        }
        let copy = ErrorState.notifications(.jobFailed).copy
        return .alert(
            JobFinishAlert(title: copy.title, body: copy.body, exitStatus: exit)
        )
    }
}
