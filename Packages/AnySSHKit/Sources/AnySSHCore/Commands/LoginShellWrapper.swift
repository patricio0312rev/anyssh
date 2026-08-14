public enum LoginShellWrapper {
    public static let shellExpression = "\"${SHELL:-/bin/sh}\""

    public static func wrap(_ script: String) -> String {
        "\(shellExpression) -lc \(ShellQuoting.singleQuote(script))"
    }
}
