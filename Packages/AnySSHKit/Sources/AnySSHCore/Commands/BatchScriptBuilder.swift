public struct RenderedBatch: Hashable, Sendable {
    public let nonce: BatchNonce
    public let script: String
    public let command: String

    public init(nonce: BatchNonce, script: String, command: String) {
        self.nonce = nonce
        self.script = script
        self.command = command
    }
}

public struct BatchScriptBuilder: Sendable {
    public init() {}

    public func render(_ batch: RemoteBatch, nonce: BatchNonce = BatchNonce()) -> RenderedBatch {
        var lines = Self.preamble(nonce)
        for (index, command) in batch.commands.enumerated() {
            lines.append("\(Self.pipeline(command)); __r \(index) $?")
        }
        lines.append("__z \(batch.commands.count)")
        let script = lines.joined(separator: "\n")
        return RenderedBatch(nonce: nonce, script: script, command: LoginShellWrapper.wrap(script))
    }

    private static func preamble(_ nonce: BatchNonce) -> [String] {
        [
            "set -o pipefail 2>/dev/null || :",
            "__n=\(ShellQuoting.singleQuote(nonce.hex))",
            #"__d=$('mktemp' -d) || exit 1"#,
            #"trap 'rm -rf "$__d"' EXIT INT HUP TERM"#,
            #"__f="$__d/section""#,
            "__r() { printf \(section) \"$__n\" \"$1\" \(count) \"$2\"; 'cat' \"$__f\"; }",
            "__z() { printf \(end) \"$__n\" \"$1\"; }",
        ]
    }

    private static func pipeline(_ command: RemoteCommand) -> String {
        guard !command.arguments.isEmpty else { return #"'false' >"$__f" 2>&1"# }
        let argv = command.arguments.map(ShellQuoting.singleQuote).joined(separator: " ")
        guard let cap = command.byteCap else { return #"\#(argv) >"$__f" 2>&1"# }
        return #"\#(argv) 2>&1 | 'head' -c \#(cap) >"$__f""#
    }

    private static let count = #"$('wc' -c <"$__f")"#
    private static let section = ShellQuoting.singleQuote(BatchRecord.sectionFormat)
    private static let end = ShellQuoting.singleQuote(BatchRecord.endFormat)
}
