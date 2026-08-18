import AnySSHCore

enum HerdrCommands {
    static let detectLabel = "herdr.detect"
    static let sessionsLabel = "herdr.sessions"
    static let snapshotLabel = "herdr.snapshot"
    static let paneReadLabel = "herdr.paneRead"
    static let configLabel = "herdr.config"
    static let focusAgentLabel = "herdr.focusAgent"
    static let focusTabLabel = "herdr.focusTab"
    static let supportedProtocol = 19

    static func detect(binary: String? = nil) -> RemoteBatch {
        if let binary {
            return RemoteBatch(commands: [
                RemoteCommand(
                    label: detectLabel,
                    arguments: [
                        "sh", "-c",
                        """
                        printf 'path\\t%s\\n' \(ShellQuoting.singleQuote(binary))
                        \(ShellQuoting.singleQuote(binary)) status client --json 2>/dev/null
                        """,
                    ]
                )
            ])
        }
        return RemoteBatch(commands: [
            RemoteCommand(label: detectLabel, arguments: ["sh", "-c", detectScript])
        ])
    }

    static func sessions(binary: String) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(label: sessionsLabel, arguments: [binary, "session", "list", "--json"])
        ])
    }

    static func snapshot(binary: String, session: String?) -> RemoteBatch {
        var arguments = scoped(binary: binary, session: session)
        arguments += ["api", "snapshot"]
        return RemoteBatch(commands: [
            RemoteCommand(label: snapshotLabel, arguments: arguments)
        ])
    }

    static func focusAgent(binary: String, session: String?, pane: String) -> RemoteBatch {
        var arguments = scoped(binary: binary, session: session)
        arguments += ["agent", "focus", pane]
        return RemoteBatch(commands: [
            RemoteCommand(label: focusAgentLabel, arguments: arguments)
        ])
    }

    static func focusTab(binary: String, session: String?, group: String) -> RemoteBatch {
        var arguments = scoped(binary: binary, session: session)
        arguments += ["tab", "focus", group]
        return RemoteBatch(commands: [
            RemoteCommand(label: focusTabLabel, arguments: arguments)
        ])
    }

    static func paneRead(binary: String, pane: String, lines: Int, session: String?) -> RemoteBatch {
        var arguments = scoped(binary: binary, session: session)
        arguments += [
            "pane", "read", pane,
            "--source", "recent-unwrapped",
            "--format", "text",
            "--lines", "\(max(1, lines))",
        ]
        return RemoteBatch(commands: [
            RemoteCommand(label: paneReadLabel, arguments: arguments)
        ])
    }

    static func config(binary: String) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: configLabel,
                arguments: [
                    "sh", "-c",
                    """
                    if [ -f "$HOME/.config/herdr/config.toml" ]; then
                      cat "$HOME/.config/herdr/config.toml"
                    elif [ -f "$HOME/.config/herdr/herdr.toml" ]; then
                      cat "$HOME/.config/herdr/herdr.toml"
                    else
                      printf ''
                    fi
                    """,
                ]
            )
        ])
    }

    private static func scoped(binary: String, session: String?) -> [String] {
        guard let session, !session.isEmpty, session != defaultSessionName else { return [binary] }
        return [binary, "--session", session]
    }

    private static let defaultSessionName = "default"

    private static let detectScript = """
        h="$HOME/.local/bin/herdr"
        if [ -x "$h" ]; then
          printf 'path\\t%s\\n' "$h"
          "$h" status client --json
        elif command -v herdr >/dev/null 2>&1; then
          p=$(command -v herdr)
          printf 'path\\t%s\\n' "$p"
          herdr status client --json
        else
          printf 'herdr:not-installed\\n'
          exit 127
        fi
        """
}
