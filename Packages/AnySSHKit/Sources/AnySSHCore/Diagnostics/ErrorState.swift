public enum ErrorState: Hashable, Sendable, CaseIterable, UserFacingError {
    case transport(TransportErrorState)
    case auth(AuthErrorState)
    case trust(TrustErrorState)
    case secrets(SecretsErrorState)
    case git(GitErrorState)
    case files(FilesErrorState)
    case mux(MuxErrorState)
    case app(AppErrorState)
    case command(CommandErrorState)
    case link(LinkErrorState)
    case session(SessionErrorState)
    case notifications(NotificationsErrorState)

    public static let allCases: [ErrorState] =
        TransportErrorState.allCases.map(ErrorState.transport)
        + AuthErrorState.allCases.map(ErrorState.auth)
        + TrustErrorState.allCases.map(ErrorState.trust)
        + SecretsErrorState.allCases.map(ErrorState.secrets)
        + GitErrorState.allCases.map(ErrorState.git)
        + FilesErrorState.allCases.map(ErrorState.files)
        + MuxErrorState.allCases.map(ErrorState.mux)
        + AppErrorState.allCases.map(ErrorState.app)
        + CommandErrorState.allCases.map(ErrorState.command)
        + LinkErrorState.allCases.map(ErrorState.link)
        + SessionErrorState.allCases.map(ErrorState.session)
        + NotificationsErrorState.allCases.map(ErrorState.notifications)

    public init?(stateID: String) {
        guard let state = Self.byStateID[stateID] else { return nil }
        self = state
    }

    public var stateID: String { member.stateID }

    public var group: ErrorStateGroup { member.group }

    public var copy: ErrorStateCopy { member.copy }

    public var owningPhase: Int { member.owningPhase }

    public var accessibilityIdentifier: String { "error.\(stateID)" }

    public var artifactPath: String { ".build/artifacts/errors/\(stateID).png" }

    private var member: any ErrorStateMember {
        switch self {
        case .transport(let state): state
        case .auth(let state): state
        case .trust(let state): state
        case .secrets(let state): state
        case .git(let state): state
        case .files(let state): state
        case .mux(let state): state
        case .app(let state): state
        case .command(let state): state
        case .link(let state): state
        case .session(let state): state
        case .notifications(let state): state
        }
    }

    private static let byStateID: [String: ErrorState] = Dictionary(
        uniqueKeysWithValues: allCases.map { ($0.stateID, $0) }
    )
}
