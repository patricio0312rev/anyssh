import Foundation

public enum ForegroundProcessCommand {
    public static func script(clientPort: Int) -> String {
        """
        p=\(clientPort)
        pid=$(lsof -nP -iTCP:$p -sTCP:ESTABLISHED -t 2>/dev/null | head -1)
        if [ -z "$pid" ]; then
          pid=$(ss -tnp 2>/dev/null | awk -v p=":$p" '$0 ~ p' \
            | sed -n 's/.*pid=\\([0-9]*\\).*/\\1/p' | head -1)
        fi
        [ -z "$pid" ] && pid=$PPID
        kids=$(ps -axo pid=,ppid= 2>/dev/null | awk -v root="$pid" '
          { parent[$1]=$2 }
          END {
            desc[root]=1; changed=1
            while (changed) {
              changed=0
              for (k in parent) if (!(k in desc) && (parent[k] in desc)) { desc[k]=1; changed=1 }
            }
            for (k in desc) if (k != root) print k
          }')
        [ -z "$kids" ] && exit 0
        for k in $kids; do
          ps -o comm= -p "$k" 2>/dev/null | sed 's/^/P /'
        done
        cwd() {
          d=$(readlink "/proc/$1/cwd" 2>/dev/null)
          [ -z "$d" ] && d=$(lsof -a -p "$1" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
          [ -n "$d" ] && echo "$2 $d"
        }
        shell=$(for k in $(ps -axo pid=,ppid= 2>/dev/null | awk -v root="$pid" '$2 == root { print $1 }'); do
          case "$(ps -o tty= -p "$k" 2>/dev/null)" in ""|"?") ;; *) echo "$k"; break ;; esac
        done)
        [ -z "$shell" ] && shell=$(ps -axo pid=,ppid= 2>/dev/null | awk -v root="$pid" '$2 == root { print $1; exit }')
        [ -n "$shell" ] && cwd "$shell" S
        for k in $kids; do
          cwd "$k" D
        done
        """
    }

    public static func processNames(from output: String) -> [String] {
        lines(output, prefix: "P ")
            .map { $0.split(separator: "/").last.map(String.init) ?? $0 }
            .map { $0.hasPrefix("-") ? String($0.dropFirst()) : $0 }
            .filter { !$0.isEmpty }
    }

    public static func workingDirectory(from output: String) -> String? {
        if let shell = lines(output, prefix: "S ").first(where: { $0.hasPrefix("/") }) {
            return shell
        }
        return lines(output, prefix: "D ").first { $0.hasPrefix("/") }
    }

    private static func lines(_ output: String, prefix: String) -> [String] {
        output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix(prefix) }
            .map { String($0.dropFirst(prefix.count)) }
    }
}
