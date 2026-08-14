public enum SimpleBinding: Hashable, Sendable {
    case chord(Chord)
    case text(String)

    public func bytes(using encoder: KeyEncoder) -> [UInt8] {
        switch self {
        case .chord(let chord): encoder.encode(chord)
        case .text(let text): Array(text.utf8)
        }
    }

    public var preview: String {
        switch self {
        case .chord(let chord): chord.label
        case .text(let text): text
        }
    }
}
