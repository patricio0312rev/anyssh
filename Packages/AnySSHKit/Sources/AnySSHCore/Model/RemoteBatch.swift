import Foundation

public struct RemoteCommand: Hashable, Sendable {
    public let label: String
    public let arguments: [String]
    public let byteCap: Int?

    public init(label: String, arguments: [String], byteCap: Int? = nil) {
        self.label = label
        self.arguments = arguments
        self.byteCap = byteCap
    }
}

public struct RemoteBatch: Hashable, Sendable {
    public let commands: [RemoteCommand]

    public init(commands: [RemoteCommand]) {
        self.commands = commands
    }
}

public struct CommandSection: Hashable, Sendable {
    public let label: String
    public let bytes: Data
    public let exitCode: Int32
    public let truncated: Bool

    public init(label: String, bytes: Data, exitCode: Int32, truncated: Bool) {
        self.label = label
        self.bytes = bytes
        self.exitCode = exitCode
        self.truncated = truncated
    }
}

public struct BatchResponse: Hashable, Sendable {
    public let sections: [CommandSection]

    public init(sections: [CommandSection]) {
        self.sections = sections
    }
}
