public enum FreshLoginShell {
    public static func isAtPrompt(processNames: [String]) -> Bool {
        let shells = processNames.filter(shellNames.contains)
        let others = processNames.filter { name in
            !shellNames.contains(name) && !name.hasPrefix(sessionHelperPrefix)
        }
        return shells.count == 1 && others.isEmpty
    }

    static let shellNames: Set<String> = [
        "sh", "bash", "zsh", "fish", "dash", "ksh", "mksh", "tcsh", "csh",
    ]

    static let sessionHelperPrefix = "sshd"
}
