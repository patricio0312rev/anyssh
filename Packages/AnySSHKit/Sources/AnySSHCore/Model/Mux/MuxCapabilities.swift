public enum SurvivalConfidence: String, CaseIterable, Sendable {
    case proven
    case unverified
    case unsupported
}

public struct MultiplexerCapabilities: Hashable, Sendable {
    public let structuredOutput: Bool
    public let agentStatus: Bool
    public let worktreeMetadata: Bool
    public let paneRead: Bool
    public let eventStream: Bool
    public let localSessionSurvival: SurvivalConfidence
    public let remoteBootstrapSurvival: SurvivalConfidence
    public let crossHostSurvival: SurvivalConfidence

    public init(
        structuredOutput: Bool,
        agentStatus: Bool,
        worktreeMetadata: Bool,
        paneRead: Bool,
        eventStream: Bool,
        localSessionSurvival: SurvivalConfidence,
        remoteBootstrapSurvival: SurvivalConfidence,
        crossHostSurvival: SurvivalConfidence
    ) {
        self.structuredOutput = structuredOutput
        self.agentStatus = agentStatus
        self.worktreeMetadata = worktreeMetadata
        self.paneRead = paneRead
        self.eventStream = eventStream
        self.localSessionSurvival = localSessionSurvival
        self.remoteBootstrapSurvival = remoteBootstrapSurvival
        self.crossHostSurvival = crossHostSurvival
    }
}

public struct MultiplexerInfo: Hashable, Sendable {
    public let kind: MultiplexerKind
    public let binaryPath: String
    public let version: String
    public let protocolVersion: Int?

    public init(kind: MultiplexerKind, binaryPath: String, version: String, protocolVersion: Int?) {
        self.kind = kind
        self.binaryPath = binaryPath
        self.version = version
        self.protocolVersion = protocolVersion
    }
}

public struct MuxKeyBindings: Hashable, Sendable {
    public let prefix: String
    public let chords: [String: String]

    public init(prefix: String, chords: [String: String]) {
        self.prefix = prefix
        self.chords = chords
    }

    public func chord(for action: String, kind: MultiplexerKind) -> String? {
        guard let value = chords[action] else { return nil }
        let normalizedPrefix = MuxPrefixValue.phase23(prefix)
        if kind == .herdr, value.lowercased().hasPrefix("prefix+") {
            let suffix = value.dropFirst("prefix+".count)
            return normalizedPrefix + ", " + MuxPrefixValue.phase23(String(suffix))
        }
        return normalizedPrefix + ", " + MuxPrefixValue.phase23(value)
    }
}

private enum MuxPrefixValue {
    static func phase23(_ value: String) -> String {
        let parts = value.split(separator: "+").map(String.init)
        guard parts.count > 1 else { return value }
        var modifiers = ""
        var key = ""
        for part in parts {
            switch part.lowercased() {
            case "c", "ctrl", "control": modifiers += "C-"
            case "m", "meta", "a", "alt", "opt", "option": modifiers += "M-"
            case "s", "shift": modifiers += "S-"
            default: key = part
            }
        }
        return modifiers + key
    }
}
