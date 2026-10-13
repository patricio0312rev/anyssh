import Foundation

public enum ClientTerminalCommand {
    public static func sessionProcessLookup(clientPort: Int) -> String {
        """
        p=\(clientPort)
        pid=$(lsof -nP -iTCP:$p -sTCP:ESTABLISHED -t 2>/dev/null | head -1)
        if [ -z "$pid" ]; then
          pid=$(ss -tnp 2>/dev/null | awk -v p=":$p$" '{ for (i = 1; i <= NF; i++) if ($i ~ p) { print; next } }' \
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
        shell=""; level="$pid"; depth=0
        while [ -z "$shell" ] && [ -n "$level" ] && [ "$depth" -lt 4 ]; do
          level=$(ps -axo pid=,ppid= 2>/dev/null | awk -v roots=" $level " 'index(roots, " " $2 " ") { printf "%s ", $1 }')
          for k in $level; do
            case "$(ps -o tty= -p "$k" 2>/dev/null | tr -d ' ')" in (""|"?"|"??") ;; (*) shell=$k; break ;; esac
          done
          depth=$((depth + 1))
        done
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
