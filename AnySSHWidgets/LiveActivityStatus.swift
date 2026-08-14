import AnySSHUI
import Foundation
import SwiftUI

@MainActor
enum LiveActivityStatus {
    static func color(for transportState: String) -> Color {
        let state = transportState.lowercased()
        if state.hasPrefix("connected") { return Theme.status.online }
        if state.hasPrefix("reconnect") || state.hasPrefix("connecting") { return Theme.status.busy }
        if state.hasPrefix("disconnected") || state.hasPrefix("failed") { return Theme.status.error }
        return Theme.status.offline
    }

    static func agentColor(for agentState: String) -> Color? {
        switch agentState.lowercased() {
        case "working": Theme.status.busy
        case "blocked": Theme.status.attention
        case "done": Theme.status.online
        default: nil
        }
    }

    static func agentLabel(for agentState: String) -> String? {
        switch agentState.lowercased() {
        case "working": "Working"
        case "blocked": "Blocked"
        case "done": "Done"
        default: nil
        }
    }

    static func uptime(_ seconds: TimeInterval) -> String {
        let total = Int(max(0, seconds))
        let hours = total / 3_600
        let minutes = (total % 3_600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
