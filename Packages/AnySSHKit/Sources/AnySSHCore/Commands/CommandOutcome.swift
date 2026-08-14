public enum CommandFailure: Error, Hashable, Sendable, UserFacingError {
    case programMissing(String)
    case signalled(Int32)
    case exited(Int32)

    public var stateID: String {
        switch self {
        case .programMissing(let program):
            Self.registeredPrograms[program] ?? ErrorState.command(.programMissing).stateID
        case .signalled: ErrorState.command(.signalled).stateID
        case .exited: ErrorState.command(.failed).stateID
        }
    }

    private static let registeredPrograms = ["git": ErrorState.git(.missing).stateID]
}

extension RemoteCommand {
    public var program: String {
        guard let first = arguments.first else { return "" }
        return first.split(separator: "/").last.map(String.init) ?? first
    }
}

extension CommandSection {
    public var failed: Bool { exitCode != 0 && !truncated }

    public func failure(program: String) -> CommandFailure? {
        guard failed else { return nil }
        switch exitCode {
        case 127: return .programMissing(program)
        case 129...192: return .signalled(exitCode - 128)
        default: return .exited(exitCode)
        }
    }
}

extension BatchResponse {
    public func failures(in batch: RemoteBatch) -> [String: CommandFailure] {
        let programs = Dictionary(batch.commands.map { ($0.label, $0.program) }) { first, _ in first }
        return sections.reduce(into: [:]) { result, section in
            result[section.label] = section.failure(program: programs[section.label] ?? "")
        }
    }
}
