public enum TerminalModeReset {
    public static let bytes: [UInt8] = Array(
        (leaveAlternateScreen + disabledPrivateModes.map(disable).joined() + keyboardDefaults + softReset)
            .utf8
    )

    static let disabledPrivateModes = [
        9, 1000, 1002, 1003, 1005, 1006, 1015, 1016, 1004, 2004, 2026,
    ]

    private static let escape = "\u{1B}"
    private static let leaveAlternateScreen = escape + "7" + escape + "[?1049l"
    private static let keyboardDefaults = escape + "[=0;1u"
    private static let softReset = escape + "[!p"

    private static func disable(_ mode: Int) -> String {
        escape + "[?\(mode)l"
    }
}
