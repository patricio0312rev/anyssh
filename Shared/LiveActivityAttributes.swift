import ActivityKit
import Foundation

nonisolated struct LiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let title: String
        let remoteName: String
        let transportState: String
        let agentState: String
        let uptime: TimeInterval
        let notification: String?
        let updatedAt: Date
    }

    let sessionID: String
}
