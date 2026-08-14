import AnySSHCore

public extension ShortcutPanel.Entry.Payload {
    func bytes(using encoder: KeyEncoder = KeyEncoder()) -> [UInt8] {
        switch self {
        case .chord(let syntaxText):
            guard let chord = try? Chord(parsing: syntaxText) else { return [] }
            return encoder.encode(chord)
        case .text(let text):
            return Array(text.utf8)
        }
    }
}
