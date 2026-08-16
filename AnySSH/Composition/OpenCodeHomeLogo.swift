enum OpenCodeHomeLogo {
    static let rows = 4
    static let columns = 39
    static let maximumScale = 2

    static func draw(_ line: Int, scale: Int, into row: inout OpenCodeHomeRow) {
        let source = line / scale
        let band = line % scale
        guard source >= 0, source < rows else { return }
        for stroke in open[source] {
            row.append(stretched(stroke.text, scale: scale, band: band), stroke.style)
        }
        row.fill(scale, .canvas)
        for stroke in code[source] {
            row.append(stretched(stroke.text, scale: scale, band: band), stroke.style)
        }
    }

    private static func stretched(_ text: String, scale: Int, band: Int) -> String {
        guard scale > 1 else { return text }
        return text.map { String(repeating: slice(of: $0, scale: scale, band: band), count: scale) }
            .joined()
    }

    private static func slice(of glyph: Character, scale: Int, band: Int) -> String {
        let upper = band < scale / 2
        switch glyph {
        case "█": return "█"
        case "▀": return upper ? "█" : " "
        case "▄": return upper ? " " : "█"
        default: return " "
        }
    }

    private static let open: [[OpenCodeHomeRow.Stroke]] = [
        [("                   ", .canvasMuted)],
        [("█▀▀█ █▀▀█ █▀▀█ █▀▀▄", .canvasMuted)],
        [
            ("█", .canvasMuted),
            ("  ", .markShaded),
            ("█ █", .canvasMuted),
            ("  ", .markShaded),
            ("█ █", .canvasMuted),
            ("▀▀▀", .markShaded),
            (" █", .canvasMuted),
            ("  ", .markShaded),
            ("█", .canvasMuted),
        ],
        [
            ("▀▀▀▀ █▀▀▀ ▀▀▀▀ ▀", .canvasMuted),
            ("▀▀", .markShadow),
            ("▀", .canvasMuted),
        ],
    ]

    private static let code: [[OpenCodeHomeRow.Stroke]] = [
        [("             ▄     ", .markBright)],
        [("█▀▀▀ █▀▀█ █▀▀█ █▀▀█", .markBright)],
        [
            ("█", .markBright),
            ("   ", .markBrightShaded),
            (" █", .markBright),
            ("  ", .markBrightShaded),
            ("█ █", .markBright),
            ("  ", .markBrightShaded),
            ("█ █", .markBright),
            ("▀▀▀", .markBrightShaded),
        ],
        [("▀▀▀▀ ▀▀▀▀ ▀▀▀▀ ▀▀▀▀", .markBright)],
    ]
}
