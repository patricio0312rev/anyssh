enum OpenCodeHomeTranscript {
    static func home(columns: Int, rows: Int) -> [UInt8] {
        let width = max(columns, minimumColumns)
        let height = max(rows, minimumRows)
        let block = block(width: width)
        let empty = blank(width: width)
        let top = max(0, (height - 1 - block.count) / 2)
        var frame = prologue
        for line in 0..<height {
            let offset = line - top
            let content =
                switch line {
                case top..<(top + block.count): block[offset]
                case height - 1: status(width: width)
                default: empty
                }
            frame += "\u{1b}[\(line + 1);1H" + content
        }
        return Array(frame.utf8)
    }

    private static let prologue = "\u{1b}[?25l\u{1b}[?7l\u{1b}[2J"
    private static let margin = 2
    private static let gapRows = 2
    private static let minimumRows = 16
    private static let minimumColumns = 51
    private static let workingDirectory = "~/src/api"
    private static let placeholder = "  Ask anything... \"Fix broken tests\""

    private static let logoBreathing = 20

    private static let hints: [OpenCodeHomeRow.Stroke] = [
        ("shift+tab ", .canvasBright),
        ("agents", .canvasMuted),
        ("  ", .canvas),
        ("ctrl+p ", .canvasBright),
        ("commands", .canvasMuted),
    ]

    private static func block(width: Int) -> [String] {
        let scale = logoScale(width: width)
        return logo(width: width, scale: scale)
            + Array(repeating: blank(width: width), count: gapRows * scale)
            + promptField(width: width)
            + [hint(width: width)]
    }

    private static func blank(width: Int) -> String {
        OpenCodeHomeRow().rendered(width: width)
    }

    private static func logoScale(width: Int) -> Int {
        let usable = width - 2 * margin
        let unit = OpenCodeHomeLogo.columns + logoBreathing
        return max(1, min(OpenCodeHomeLogo.maximumScale, usable / unit))
    }

    private static func logo(width: Int, scale: Int) -> [String] {
        let span = OpenCodeHomeLogo.columns * scale
        let left = max(margin, (width - span) / 2)
        return (0..<(OpenCodeHomeLogo.rows * scale)).map { line in
            var row = OpenCodeHomeRow()
            row.fill(left, .canvas)
            OpenCodeHomeLogo.draw(line, scale: scale, into: &row)
            return row.rendered(width: width)
        }
    }

    private static func promptField(width: Int) -> [String] {
        let interior = max(0, width - 2 * margin - 1)
        return [
            lined(width: width, interior: interior) { _ in },
            lined(width: width, interior: interior) { row in
                row.append(placeholder, .fieldMuted)
            },
            lined(width: width, interior: interior) { _ in },
            lined(width: width, interior: interior) { row in
                row.append("  ", .field)
                row.append("Build", .fieldAccent)
                row.append(" ", .field)
                row.append("·", .fieldMuted)
                row.append(" ", .field)
                row.append("GPT-5.6 Luna", .fieldBright)
                row.append(" ", .field)
                row.append("OpenAI", .fieldMuted)
            },
            base(width: width, interior: interior),
        ]
    }

    private static func lined(
        width: Int,
        interior: Int,
        content: (inout OpenCodeHomeRow) -> Void
    ) -> String {
        var row = OpenCodeHomeRow()
        row.fill(margin, .canvas)
        row.append("┃", .canvasAccent)
        let start = row.count
        content(&row)
        row.fill(interior - (row.count - start), .field)
        row.fill(margin, .canvas)
        return row.rendered(width: width)
    }

    private static func base(width: Int, interior: Int) -> String {
        var row = OpenCodeHomeRow()
        row.fill(margin, .canvas)
        row.append("╹", .canvasAccent)
        row.append(String(repeating: "▀", count: interior), .rule)
        row.fill(margin, .canvas)
        return row.rendered(width: width)
    }

    private static func hint(width: Int) -> String {
        let trailing = hints.reduce(0) { $0 + $1.text.count }
        var row = OpenCodeHomeRow()
        row.fill(margin, .canvas)
        row.append(workingDirectory, .canvasMuted)
        row.fill(width - 2 * margin - workingDirectory.count - trailing, .canvas)
        for stroke in hints {
            row.append(stroke.text, stroke.style)
        }
        row.fill(margin, .canvas)
        return row.rendered(width: width)
    }

    private static func status(width: Int) -> String {
        var row = OpenCodeHomeRow()
        row.fill(margin, .canvas)
        row.append("⊙ ", .canvasOnline)
        row.append("11 MCP", .canvasBright)
        return row.rendered(width: width)
    }
}
