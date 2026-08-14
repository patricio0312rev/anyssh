public struct Chord: Hashable, Sendable {
    public let steps: [KeyStroke]

    public init(_ steps: [KeyStroke]) {
        self.steps = steps
    }

    public init(parsing text: String) throws(ChordSyntaxError) {
        self.init(try ChordParser.steps(in: text))
    }

    public var label: String {
        steps.map(\.label).joined(separator: " ")
    }
}
