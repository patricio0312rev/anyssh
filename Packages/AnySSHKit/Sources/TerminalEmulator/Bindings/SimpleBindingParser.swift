public enum SimpleBindingParser {
    public static func parse(
        modifier: KeyModifiers,
        text: String
    ) throws(SimpleBindingSyntaxError) -> SimpleBinding {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .emptyText
        }
        guard !text.contains(where: { $0 == "\n" || $0 == "\r" }) else {
            throw .newlineInText
        }

        let verbatim: String
        if text.hasPrefix(textPrefix) {
            verbatim = String(text.dropFirst(textPrefix.count))
            guard !verbatim.trimmingCharacters(in: .whitespaces).isEmpty else { throw .emptyText }
            return .text(verbatim)
        }
        verbatim = text
        guard !modifier.isEmpty else { return .text(verbatim) }

        let characters = Array(verbatim)
        var steps = [KeyStroke]()
        var segment = ""
        var index = 0

        while index < characters.count {
            if characters[index] == "," {
                if index + 1 < characters.count, characters[index + 1] == "," {
                    flush(segment: &segment, modifier: modifier, into: &steps)
                    steps.append(KeyStroke(.character(",")))
                    index += 2
                } else if index + 1 == characters.count {
                    throw .trailingComma
                } else if segment.isEmpty, steps.isEmpty {
                    throw .leadingComma
                } else {
                    flush(segment: &segment, modifier: modifier, into: &steps)
                    index += 1
                }
            } else {
                segment.append(characters[index])
                index += 1
            }
        }
        flush(segment: &segment, modifier: modifier, into: &steps)
        guard !steps.isEmpty else { throw .emptyText }
        return .chord(Chord(steps))
    }

    private static let textPrefix = "text:"

    private static func flush(
        segment: inout String,
        modifier: KeyModifiers,
        into steps: inout [KeyStroke]
    ) {
        guard !segment.isEmpty else { return }
        let characters = Array(segment)
        steps.append(KeyStroke(.character(characters[0]), modifier))
        steps.append(contentsOf: characters.dropFirst().map { KeyStroke(.character($0)) })
        segment = ""
    }
}
