import Foundation

public enum ClientTerminalCommand {
    public static func sessionProcessLookup(clientPort: Int) -> String {
        """
        p=\(clientPort)
        pid=$(lsof -nP -iTCP:$p -sTCP:ESTABLISHED -t 2>/dev/null | head -1)
        if [ -z "$pid" ]; then
          pid=$(ss -tnp 2>/dev/null | awk -v p=":$p" '$0 ~ p' \
            | sed -n 's/.*pid=\\([0-9]*\\).*/\\1/p' | head -1)
        fi
        if [ -z "$pid" ]; then
          for k in $(ps -u "$(id -u)" -o pid= 2>/dev/null); do
            cat "/proc/$k/environ" 2>/dev/null | tr '\\0' '\\n' | grep -q "^SSH_CONNECTION=[^ ]* $p " || continue
            pp=$(ps -o ppid= -p "$k" 2>/dev/null | tr -d ' ')
            cat "/proc/$pp/environ" 2>/dev/null | tr '\\0' '\\n' | grep -q "^SSH_CONNECTION=[^ ]* $p " && continue
            pid=$pp; break
          done
        fi
        [ -z "$pid" ] && exit 0
        """
    }

    public static let interactiveShellLookup = """
        shell=$(for k in $(ps -axo pid=,ppid= 2>/dev/null | awk -v root="$pid" '$2 == root { print $1 }'); do
          case "$(ps -o tty= -p "$k" 2>/dev/null)" in (""|"?") ;; (*) echo "$k"; break ;; esac
        done)
        """

    public static func script(clientPort: Int) -> String {
        """
        \(sessionProcessLookup(clientPort: clientPort))
        \(interactiveShellLookup)
        [ -n "$shell" ] && ps -o tty= -p "$shell" 2>/dev/null
        """
    }

    public static func terminal(from output: String) -> String? {
        output.split(whereSeparator: \.isNewline)
            .lazy
            .compactMap { terminalName(String($0)) }
            .first
    }

    public static func terminalName(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        let name = trimmed.hasPrefix(devicePrefix) ? String(trimmed.dropFirst(devicePrefix.count)) : trimmed
        guard !name.isEmpty, !unattached.contains(name) else { return nil }
        return name
    }

    private static let devicePrefix = "/dev/"
    private static let unattached: Set<String> = ["?", "??"]
}
