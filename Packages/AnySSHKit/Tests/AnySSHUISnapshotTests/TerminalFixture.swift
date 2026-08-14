import AnySSHCore

@testable import AnySSHUI

enum TerminalFixture {
    static let title = "dev@build-box: ~/src/anyssh"
    static let workingDirectory = "/home/dev/src/anyssh"
    static let clipboardPayload = "git status --short"

    static var frame: [UInt8] {
        Array(screen.utf8)
    }

    static func engine(renderer: TerminalRenderer) -> SwiftTermEngine {
        let engine = SwiftTermEngine(size: .standard, renderer: renderer)
        engine.feed(frame[...])
        return engine
    }

    private static let screen = """
        \u{1b}[?25l\u{1b}]0;\(title)\u{7}\u{1b}]7;file://build-box\(workingDirectory)\u{1b}\\\
        \u{1b}[2J\u{1b}[H\
        \u{1b}[35manyssh\u{1b}[0m on \u{1b}[36mmain\u{1b}[0m [\u{1b}[33m!?\u{1b}[0m] \
        via \u{1b}[32mswift v6.3.3\u{1b}[0m\r\n\
        \u{1b}[90m➜\u{1b}[0m git status --short\r\n\
        \u{1b}[32mM \u{1b}[0m Sources/AnySSHUI/Terminal/SwiftTerm/SwiftTermEngine.swift\r\n\
        \u{1b}[32mM \u{1b}[0m Sources/AnySSHUI/Terminal/Host/TerminalHostController.swift\r\n\
        \u{1b}[31m D\u{1b}[0m Sources/AnySSHUI/Terminal/Legacy.swift\r\n\
        \u{1b}[31m?? \u{1b}[0m Tests/AnySSHUISnapshotTests/TerminalSnapshotTests.swift\r\n\
        \r\n\
        \u{1b}[90m➜\u{1b}[0m swift test --filter RendererSelectionTests\r\n\
        \u{1b}[90m[0/1]\u{1b}[0m Planning build\r\n\
        Building for debugging...\r\n\
        \u{1b}[32mBuild complete!\u{1b}[0m (4.71s)\r\n\
        \u{1b}[34m◇\u{1b}[0m Test run started.\r\n\
        \u{1b}[34m↳\u{1b}[0m Suite RendererSelectionTests started.\r\n\
        \u{1b}[32m✔\u{1b}[0m Test metalAndCoreTextRenderTheSameScreen passed after 0.081 seconds.\r\n\
        \u{1b}[32m✔\u{1b}[0m Test forcingCoreTextKeepsTheFallbackLive passed after 0.012 seconds.\r\n\
        \u{1b}[32m✔\u{1b}[0m Suite RendererSelectionTests passed after 0.094 seconds.\r\n\
        \r\n\
        \u{1b}[90m➜\u{1b}[0m ssh dev@192.0.2.10 -- uname -sr\r\n\
        Darwin 25.5.0\r\n\
        \u{1b}[90m➜\u{1b}[0m \u{1b}[7m \u{1b}[0m\r\n
        """
}
