public struct GitInvocation: Hashable, Sendable {
    public let arguments: [String]

    public let minimumGitVersion: String

    static let executable = "git"

    static let globalArguments = [
        "--no-pager",
        "-c", "core.quotePath=false",
        "-c", "color.ui=false",
        "-c", "diff.renames=true",
        "-c", "log.showSignature=false",
    ]

    static let diffFlags = ["--no-ext-diff", "--no-textconv", "--src-prefix=a/", "--dst-prefix=b/"]

    public func arguments(in directory: String) -> [String] {
        guard let executable = arguments.first else { return arguments }
        return [executable, "-C", directory] + arguments.dropFirst()
    }
}
