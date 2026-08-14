import SwiftUI

public enum StatusToastSeverity: String, Sendable, Hashable, CaseIterable {
    case success
    case busy
    case attention
    case error
    case offline

    public var color: Color {
        switch self {
        case .success: Theme.status.online
        case .busy: Theme.status.busy
        case .attention: Theme.status.attention
        case .error: Theme.status.error
        case .offline: Theme.status.offline
        }
    }

    public var symbolName: String {
        switch self {
        case .success: "checkmark.circle.fill"
        case .busy: "clock.fill"
        case .attention: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        case .offline: "moon.fill"
        }
    }

    public var dwell: Duration {
        switch self {
        case .success: .seconds(2)
        case .busy: .seconds(3)
        case .attention: .seconds(4)
        case .offline: .seconds(4)
        case .error: .seconds(6)
        }
    }
}
