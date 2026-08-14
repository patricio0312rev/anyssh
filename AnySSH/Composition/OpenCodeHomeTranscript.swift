enum OpenCodeHomeTranscript {
    private static let accent = "\u{1b}[38;2;171;157;242m"
    private static let bright = "\u{1b}[1m\u{1b}[38;2;252;252;250m"
    private static let muted = "\u{1b}[38;2;147;146;147m"
    private static let cyan = "\u{1b}[38;2;120;220;232m"
    private static let green = "\u{1b}[38;2;169;220;118m"
    private static let reset = "\u{1b}[0m"
    private static let caret = "\u{1b}[9;6H"

    static let home = """
        \r
        \(accent) ██████████\(reset)\r
        \(accent) ██      ██\(reset)   \(bright)opencode\(reset)  \(muted)v0.4.2\(reset)\r
        \(accent) ██      ██\(reset)   \(cyan)~/src/api\(reset)\r
        \(accent) ██      ██\(reset)   \(muted)claude-opus-4\(reset)\r
        \(accent) ██████████\(reset)   \(green)● ready\(reset)\r
        \r
        \(muted) ╭──────────────────────────────╮\(reset)\r
        \(muted) │\(reset)                              \(muted)│\(reset)\r
        \(muted) ╰──────────────────────────────╯\(reset)\r
        \(muted)   /help    /model    /undo\(reset)\
        \(caret)
        """
}
