public enum MultiplexerIdentifier {
    public static let open = "multiplexer.open"
    public static let paneList = "mux.panes"
    public static let paneListClose = "mux.panes.close"
    public static let paneListFailure = "mux.panes.failure"

    public static func pane(_ id: String) -> String {
        "mux.pane.\(id)"
    }

    public static func attaching(_ id: String) -> String {
        "mux.attaching.\(id)"
    }
}
