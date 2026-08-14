import Foundation
import os

@MainActor
public final class SessionSwitchSignpost {
    public struct Handle {
        let state: OSSignpostIntervalState
        let started: ContinuousClock.Instant
    }

    private static let subsystem = "com.patricio.anyssh"
    private static let category = "session-switch"
    private static let measurementLimit = 200
    private static let intervalName: StaticString = "session.switch"

    private let poster = OSSignposter(subsystem: subsystem, category: category)
    private let log = OSLog(subsystem: subsystem, category: category)

    public private(set) static var measured: [Double] = []

    public init() {}

    public func begin() -> Handle {
        Handle(state: poster.beginInterval(Self.intervalName), started: .now)
    }

    public func end(_ handle: Handle) {
        let duration = handle.started.duration(to: .now)
        let milliseconds =
            Double(duration.components.seconds) * 1_000
            + Double(duration.components.attoseconds) / 1e15
        poster.endInterval(Self.intervalName, handle.state)
        os_log("session.switch duration=%.1fms", log: log, type: .default, milliseconds)
        Self.measured.append(milliseconds)
        if Self.measured.count > Self.measurementLimit {
            Self.measured.removeFirst(Self.measured.count - Self.measurementLimit)
        }
    }
}
