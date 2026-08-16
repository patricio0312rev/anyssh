struct OpenCodeHomeRow {
    typealias Stroke = (text: String, style: OpenCodeHomeStyle)

    private var strokes: [Stroke] = []
    private(set) var count = 0

    mutating func append(_ text: String, _ style: OpenCodeHomeStyle) {
        guard !text.isEmpty else { return }
        strokes.append((text, style))
        count += text.count
    }

    mutating func fill(_ cells: Int, _ style: OpenCodeHomeStyle) {
        guard cells > 0 else { return }
        append(String(repeating: " ", count: cells), style)
    }

    func rendered(width: Int) -> String {
        var line = ""
        for stroke in strokes {
            line += stroke.style.sgr + stroke.text
        }
        if count < width {
            line += OpenCodeHomeStyle.canvas.sgr + String(repeating: " ", count: width - count)
        }
        return line + "\u{1b}[0m"
    }
}
