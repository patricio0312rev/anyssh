public enum TerminalLinkFixture {
    public static let columns = 80
    public static let rows = 24

    public static let url = "https://example.com/releases/latest"
    public static let urlRow = 6
    public static let urlColumn = 13

    public static let refusedURL = "ssh://git@example.com/anyssh/AnySSH.git"
    public static let refusedRow = 7
    public static let refusedColumn = 11

    public static let plainRow = 0
    public static let plainColumn = 0

    public static let screen = """
        Last login: Mon Aug 10 09:41:22 on ttys001\r
        dev@workstation ~ % git remote -v\r
        origin  https://github.com/anyssh/AnySSH.git (fetch)\r
        origin  https://github.com/anyssh/AnySSH.git (push)\r
        \r
        dev@workstation ~ % cat notes.txt\r
        Docs live at https://example.com/releases/latest\r
        Clone with ssh://git@example.com/anyssh/AnySSH.git\r
        dev@workstation ~ % _\r
        """
}
