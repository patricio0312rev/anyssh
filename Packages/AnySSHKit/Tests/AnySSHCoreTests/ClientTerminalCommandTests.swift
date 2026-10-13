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
    @Test func theShellLookupSkipsPaddedNoTerminalChildrenAndWalksDown() throws {
        let fakeProcessTable = """
            ps() {
              case "$*" in
                "-axo pid=,ppid=") printf '  200   100\\n  201   100\\n  300   200\\n  400   999\\n' ;;
                "-o tty= -p 200") printf '??      \\n' ;;
                "-o tty= -p 201") printf '?\\n' ;;
                "-o tty= -p 300") printf 'ttys007 \\n' ;;
                "-o tty= -p 400") printf 'ttys999\\n' ;;
              esac
            }
            pid=100
            """
        let script = [
            fakeProcessTable,
            ClientTerminalCommand.interactiveShellLookup,
            "printf %s \"$shell\"",
        ].joined(separator: "\n")
        let outcome = try CommandsSubprocess.run("/bin/sh", ["-s"], stdin: Data(script.utf8))
        #expect(String(decoding: outcome.stdout, as: UTF8.self) == "300")
    }

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
