public enum MuxAttachCommand {
    public static func tmux(binary: String, target: MuxTarget) -> String {
        var command =
            "\(ShellQuoting.singleQuote(binary)) attach-session "
            + "-t \(ShellQuoting.singleQuote(target.session.rawValue))"
        if let pane = target.pane {
            command += " \\; select-pane -t \(ShellQuoting.singleQuote(pane.rawValue))"
        } else if let group = target.group {
            command += " \\; select-window -t \(ShellQuoting.singleQuote(group.rawValue))"
        }
        return command
    }

    public static func herdr(binary: String, target: MuxTarget) -> String {
        "\(ShellQuoting.singleQuote(binary)) session attach "
            + "\(ShellQuoting.singleQuote(target.session.rawValue))"
    }
}
