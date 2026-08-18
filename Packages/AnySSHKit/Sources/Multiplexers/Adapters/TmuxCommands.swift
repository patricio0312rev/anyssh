import AnySSHCore

enum TmuxCommands {
    static let detectLabel = "tmux.detect"
    static let sessionsLabel = "tmux.sessions"
    static let windowsLabel = "tmux.windows"
    static let panesLabel = "tmux.panes"
    static let prefixLabel = "tmux.prefix"
    static let captureLabel = "tmux.capture"
    static let selectWindowLabel = "tmux.selectWindow"
    static let selectPaneLabel = "tmux.selectPane"

    static let sessionFormat = "#{session_id}\t#{session_name}\t#{session_attached}"
    static let windowFormat =
        "#{session_id}\t#{window_id}\t#{window_name}\t#{window_active}"
    static let paneFormat =
        "#{session_id}\t#{window_id}\t#{pane_id}\t#{pane_title}\t#{pane_current_path}\t#{pane_active}"

    static func detect(binary: String = "tmux") -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(label: detectLabel, arguments: [binary, "-V"])
        ])
    }

    static func sessions(binary: String) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: sessionsLabel,
                arguments: [binary, "list-sessions", "-F", sessionFormat]
            )
        ])
    }

    static func snapshot(binary: String) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: sessionsLabel,
                arguments: [binary, "list-sessions", "-F", sessionFormat]
            ),
            RemoteCommand(
                label: windowsLabel,
                arguments: [binary, "list-windows", "-a", "-F", windowFormat]
            ),
            RemoteCommand(
                label: panesLabel,
                arguments: [binary, "list-panes", "-a", "-F", paneFormat]
            ),
        ])
    }

    static func prefix(binary: String) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: prefixLabel,
                arguments: [binary, "show-options", "-gv", "prefix"]
            )
        ])
    }

    static func focus(binary: String, group: String?, pane: String?) -> RemoteBatch {
        var commands = [RemoteCommand]()
        if let group {
            commands.append(
                RemoteCommand(
                    label: selectWindowLabel,
                    arguments: [binary, "select-window", "-t", group]
                )
            )
        }
        if let pane {
            commands.append(
                RemoteCommand(
                    label: selectPaneLabel,
                    arguments: [binary, "select-pane", "-t", pane]
                )
            )
        }
        return RemoteBatch(commands: commands)
    }

    static func capture(binary: String, pane: String, lines: Int) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: captureLabel,
                arguments: [
                    binary, "capture-pane", "-p", "-t", pane, "-S", "-\(max(1, lines))",
                ]
            )
        ])
    }
}
