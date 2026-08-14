import AnySSHCore

public enum CapabilityProbeCommand {
    public static let label = "capabilities"

    public static func batch() -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(label: label, arguments: ["sh", "-c", script])
        ])
    }

    static let script = #"""
        printf "anyssh-capabilities/1\n"
        printf "shell\t%s\n" "${SHELL:-/bin/sh}"
        printf "platform\t%s\n" "$(uname -sm 2>/dev/null)"
        printf "model\t%s\n" "$(sysctl -n hw.model 2>/dev/null || true)"
        printf "product\t%s\n" "$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)"
        printf "locale\t%s\n" "${LC_ALL:-${LANG:-C}}"
        printf "home\t%s\n" "${HOME:-}"
        printf "path\t%s\n" "${PATH:-}"
        __anyssh_path() {
            __anyssh_candidate=$(command -v "$1" 2>/dev/null) || __anyssh_candidate=
            case "$__anyssh_candidate" in
                /*) printf "%s" "$__anyssh_candidate" ;;
                ~/*) printf "%s/%s" "$HOME" "${__anyssh_candidate#~/}" ;;
                *) printf "" ;;
            esac
        }
        __anyssh_tool() {
            __anyssh_tool_path=$(__anyssh_path "$1")
            printf "%s.path\t%s\n" "$1" "$__anyssh_tool_path"
            if [ -z "$__anyssh_tool_path" ]; then
                printf "%s.version\t\n" "$1"
                if [ "$1" = "herdr" ]; then
                    printf "herdr.protocol\t\n"
                fi
                return 0
            fi
            case "$1" in
                git) __anyssh_tool_version=$("$__anyssh_tool_path" --version 2>/dev/null) ;;
                tmux) __anyssh_tool_version=$("$__anyssh_tool_path" -V 2>/dev/null) ;;
                herdr) __anyssh_tool_version=$("$__anyssh_tool_path" --version 2>/dev/null) ;;
            esac
            printf "%s.version\t%s\n" "$1" "$__anyssh_tool_version"
            if [ "$1" = "herdr" ]; then
                __anyssh_protocol=$("$__anyssh_tool_path" status client --json 2>/dev/null | sed -nE "s/.*\"protocol\"[[:space:]]*:[[:space:]]*([0-9]+).*/\1/p" | head -n 1)
                printf "herdr.protocol\t%s\n" "$__anyssh_protocol"
            fi
        }
        __anyssh_tool git
        __anyssh_tool tmux
        __anyssh_tool herdr
        """#
}
