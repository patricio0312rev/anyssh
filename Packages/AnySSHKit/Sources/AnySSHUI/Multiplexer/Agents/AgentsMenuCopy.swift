import AnySSHCore

enum AgentsMenuCopy {
    static let title = "Agents"
    static let loading = "Loading agents"
    static let empty = "No agents running on this host"
    static let openLabel = "Agents"

    static func location(of entry: MuxAgentEntry) -> String? {
        let parts = [entry.kind?.name, entry.tabTitle.map(tab)].compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: Theme.metaSeparator)
    }

    private static func tab(_ label: String) -> String {
        label.allSatisfy(\.isNumber) ? "Tab \(label)" : label
    }
}
