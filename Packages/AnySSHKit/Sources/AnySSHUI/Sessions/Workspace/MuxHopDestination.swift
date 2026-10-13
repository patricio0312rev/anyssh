import AnySSHCore

enum MuxHopDestination: Sendable {
    case session(MuxSessionID)
    case group(MuxGroupID, of: MuxSessionID)

    func jump(with navigator: MuxNavigator) async throws -> MuxJumpOutcome {
        switch self {
        case .session(let session):
            try await navigator.jump(toSession: session)
        case .group(let group, of: let session):
            try await navigator.jump(toGroup: MuxTarget(session: session, group: group))
        }
    }
}
