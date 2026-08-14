enum TerminalScenario: String, Equatable, CaseIterable {
    case gestures = "terminal.gestures"
    case links = "terminal.links"
    case clipboard = "terminal.clipboard"
    case clipboardTmuxHint = "terminal.clipboard.tmux"
    case pasteConfirm = "terminal.pasteConfirm"
}
