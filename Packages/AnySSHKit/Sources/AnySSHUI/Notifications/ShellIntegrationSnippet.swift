import Foundation

public enum ShellIntegrationSnippet {
    public static let text = """
        # AnySSH job-finish alerts. Append to ~/.zshrc or ~/.bashrc.
        if [ -n "$ZSH_VERSION" ]; then
          __anyssh_mark_done() { printf '\\033]133;D;%s\\007' "$?"; }
          autoload -Uz add-zsh-hook
          add-zsh-hook precmd __anyssh_mark_done
        elif [ -n "$BASH_VERSION" ]; then
          __anyssh_mark_done() { local s=$?; printf '\\033]133;D;%s\\007' "$s"; }
          PROMPT_COMMAND="__anyssh_mark_done${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
        fi
        """
}
