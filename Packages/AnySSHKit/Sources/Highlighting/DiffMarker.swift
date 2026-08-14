public enum DiffMarker {
    public static func strip(_ rawLine: String) -> String {
        guard let first = rawLine.first, first == "+" || first == "-" || first == " " else {
            return rawLine
        }
        return String(rawLine.dropFirst())
    }

    public static func strip(lines: [String]) -> [String] {
        lines.map(strip)
    }
}
