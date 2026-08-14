public enum ErrorStateGroup: String, CaseIterable, Sendable {
    case transport
    case auth
    case trust
    case secrets
    case git
    case files
    case mux
    case app
    case command
    case link
    case session
    case notifications
}
