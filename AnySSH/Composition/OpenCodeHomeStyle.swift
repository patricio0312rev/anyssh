struct OpenCodeHomeStyle {
    let foreground: String
    let background: String
    var bold = false

    var sgr: String {
        let weight = bold ? "0;1" : "0"
        return "\u{1b}[\(weight);38;2;\(foreground);48;2;\(background)m"
    }
}

extension OpenCodeHomeStyle {
    private static let page = "45;42;46"
    private static let panel = "25;24;26"
    private static let dimShade = "71;68;71"
    private static let brightShade = "97;95;97"
    private static let neutral = "255;255;255"
    private static let muted = "147;146;147"
    private static let bright = "252;252;250"
    private static let accent = "120;220;232"
    private static let online = "169;220;118"

    static let canvas = Self(foreground: neutral, background: page)
    static let canvasMuted = Self(foreground: muted, background: page)
    static let canvasBright = Self(foreground: bright, background: page)
    static let canvasAccent = Self(foreground: accent, background: page)
    static let canvasOnline = Self(foreground: online, background: page)
    static let rule = Self(foreground: panel, background: page)

    static let field = Self(foreground: neutral, background: panel)
    static let fieldMuted = Self(foreground: muted, background: panel)
    static let fieldBright = Self(foreground: bright, background: panel)
    static let fieldAccent = Self(foreground: accent, background: panel)

    static let markShadow = Self(foreground: dimShade, background: page)
    static let markShaded = Self(foreground: muted, background: dimShade)
    static let markBright = Self(foreground: bright, background: page, bold: true)
    static let markBrightShaded = Self(foreground: bright, background: brightShade, bold: true)
}
