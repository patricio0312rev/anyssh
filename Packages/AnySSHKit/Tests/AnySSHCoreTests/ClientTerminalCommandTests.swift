import Foundation
import Testing

@testable import AnySSHCore

@Suite struct ClientTerminalCommandTests {
    @Test func ourTerminalIsReadFromThePsColumnWithoutTheDevicePrefix() {
        #expect(ClientTerminalCommand.terminal(from: "pts/3\n") == "pts/3")
        #expect(ClientTerminalCommand.terminal(from: "  ttys004 \n") == "ttys004")
        #expect(ClientTerminalCommand.terminal(from: "/dev/pts/3") == "pts/3")
    }

    @Test func aProcessWithoutATerminalNamesNone() {
        #expect(ClientTerminalCommand.terminal(from: "?\n") == nil)
        #expect(ClientTerminalCommand.terminal(from: "??\n") == nil)
        #expect(ClientTerminalCommand.terminal(from: "") == nil)
    }

    @Test func tmuxClientTerminalsAndPsTerminalsNameTheSameDevice() {
        #expect(
            ClientTerminalCommand.terminalName("/dev/ttys004")
                == ClientTerminalCommand.terminal(from: "ttys004\n")
        )
    }

    #if os(macOS)
    @Test func bothProbeScriptsParseUnderTheMacOSSystemShell() throws {
        for script in [
            ClientTerminalCommand.script(clientPort: 52_000),
            ForegroundProcessCommand.script(clientPort: 52_000),
        ] {
            let outcome = try CommandsSubprocess.run("/bin/sh", ["-n"], stdin: Data(script.utf8))
            #expect(outcome.exitCode == 0)
        }
    }
    #endif
}
