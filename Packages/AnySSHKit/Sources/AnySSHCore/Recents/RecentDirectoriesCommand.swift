public enum RecentDirectoriesCommand {
    public static let label = "recent-directories"
    public static let protocolVersion = "anyssh-recents/1"

    public static func batch(limit: Int = 40) -> RemoteBatch {
        let capped = max(1, min(limit, 100))
        return RemoteBatch(commands: [
            RemoteCommand(
                label: label,
                arguments: ["sh", "-c", script(limit: capped)],
                byteCap: 512 * 1024
            )
        ])
    }

    static func script(limit: Int) -> String {
        """
        printf '\(protocolVersion)\\n'
        __limit=\(limit)
        __emit() {
          __path=$1
          __ms=$2
          __src=$3
          case "$__path" in
            /*) ;;
            *) return 0 ;;
          esac
          case "$__path" in
            /|/tmp|/var|/private|/private/tmp|"$HOME"|"$HOME/") return 0 ;;
          esac
          [ -d "$__path" ] || return 0
          printf '%s\\t%s\\t%s\\n' "$__src" "$__ms" "$__path"
        }
        __cursor_dfs() {
          __rem=$1
          __base=$2
          if [ -z "$__rem" ]; then
            [ -d "$__base" ] || return 1
            printf '%s' "$__base"
            return 0
          fi
          __head=
          __tail=$__rem
          while :; do
            case "$__tail" in
              *-*)
                __comp=${__tail%%-*}
                __rest=${__tail#*-}
                __cand=${__base}/${__head}${__comp}
                if [ -d "$__cand" ]; then
                  if __out=$(__cursor_dfs "$__rest" "$__cand"); then
                    printf '%s' "$__out"
                    return 0
                  fi
                fi
                __head=${__head}${__comp}-
                __tail=$__rest
                ;;
              *)
                __cand=${__base}/${__head}${__tail}
                if [ -d "$__cand" ]; then
                  printf '%s' "$__cand"
                  return 0
                fi
                return 1
                ;;
            esac
          done
        }
        __claude_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
        if [ -f "$__claude_dir/history.jsonl" ]; then
          tail -n 2000 "$__claude_dir/history.jsonl" 2>/dev/null | while IFS= read -r __line || [ -n "$__line" ]; do
            __project=$(printf '%s' "$__line" | sed -n 's/.*"project"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' | head -n 1)
            __ts=$(printf '%s' "$__line" | sed -n 's/.*"timestamp"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p' | head -n 1)
            [ -n "$__project" ] && [ -n "$__ts" ] && __emit "$__project" "$__ts" claude
          done
        elif [ -d "$__claude_dir/projects" ]; then
          find "$__claude_dir/projects" -type f -name '*.jsonl' 2>/dev/null | head -n 40 | while IFS= read -r __file; do
            __ms=$(stat -c %Y "$__file" 2>/dev/null || stat -f %m "$__file" 2>/dev/null || printf 0)
            __ms=$((__ms * 1000))
            __cwd=$(sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' "$__file" 2>/dev/null | head -n 1)
            [ -n "$__cwd" ] && __emit "$__cwd" "$__ms" claude
          done
        fi
        __codex_home="${CODEX_HOME:-$HOME/.codex}"
        if [ -d "$__codex_home/sessions" ]; then
          ls -dt "$__codex_home"/sessions/*/*/*/rollout-*.jsonl 2>/dev/null | head -n 40 | while IFS= read -r __file; do
            __line=$(head -n 1 "$__file" 2>/dev/null) || continue
            __cwd=$(printf '%s' "$__line" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' | head -n 1)
            __ts=$(printf '%s' "$__line" | sed -n 's/.*"timestamp"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' | head -n 1)
            __ms=0
            if [ -n "$__ts" ]; then
              __ms=$(date -j -f '%Y-%m-%dT%H:%M:%S' "${__ts%%.*}" +%s 2>/dev/null || date -d "${__ts%%.*}" +%s 2>/dev/null || printf 0)
              __ms=$((__ms * 1000))
            fi
            [ -n "$__cwd" ] && __emit "$__cwd" "$__ms" codex
          done
        fi
        if [ -d "$HOME/.cursor/projects" ]; then
          ls -dt "$HOME"/.cursor/projects/*/ 2>/dev/null | head -n 40 | while IFS= read -r __dir; do
            __name=$(basename "${__dir%/}")
            case "$__name" in
              ''|*[!0-9]*) ;;
              *) continue ;;
            esac
            case "$__name" in
              *var-folders-*|T-*) continue ;;
            esac
            __ms=$(stat -c %Y "$__dir" 2>/dev/null || stat -f %m "$__dir" 2>/dev/null || printf 0)
            __ms=$((__ms * 1000))
            __path=$(__cursor_dfs "$__name" "")
            [ -n "$__path" ] && __emit "$__path" "$__ms" cursor
          done
        fi
        __xdg="${XDG_DATA_HOME:-$HOME/.local/share}"
        __oc_db="$__xdg/opencode/opencode.db"
        __oc_json="$__xdg/opencode/storage/project"
        if command -v sqlite3 >/dev/null 2>&1 && [ -f "$__oc_db" ]; then
          sqlite3 -readonly "$__oc_db" "select worktree, time_updated from project order by time_updated desc limit $__limit;" 2>/dev/null | while IFS='|' read -r __wt __ms; do
            [ -n "$__wt" ] && __emit "$__wt" "$__ms" opencode
          done
        elif [ -d "$__oc_json" ]; then
          for __file in "$__oc_json"/*.json; do
            [ -f "$__file" ] || continue
            __wt=$(sed -n 's/.*"worktree"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' "$__file" | head -n 1)
            __ms=$(sed -n 's/.*"updated"[[:space:]]*:[[:space:]]*\\([0-9][0-9]*\\).*/\\1/p' "$__file" | head -n 1)
            [ -z "$__ms" ] && __ms=0
            [ -n "$__wt" ] && __emit "$__wt" "$__ms" opencode
          done
        fi
        """
    }
}
