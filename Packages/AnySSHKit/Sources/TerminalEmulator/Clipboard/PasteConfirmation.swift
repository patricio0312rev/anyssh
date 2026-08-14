public enum PasteConfirmation: Equatable, Sendable {
    case sendImmediately(PastePayload)
    case confirm(PastePayload)

    public static func plan(for text: String) -> PasteConfirmation {
        let payload = PastePayload(text)
        if payload.isMultiline {
            return .confirm(payload)
        }
        return .sendImmediately(payload)
    }
}

public struct PasteConfirmationContent: Equatable, Sendable {
    public let lineCount: Int
    public let preview: String
    public let endsWithLineBreak: Bool

    public init(payload: PastePayload, previewCharacterLimit: Int = 240) {
        lineCount = payload.lineCount
        endsWithLineBreak = payload.endsWithLineBreak
        preview = Self.preview(from: payload.text, limit: previewCharacterLimit)
    }

    private static func preview(from text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        let end = text.index(text.startIndex, offsetBy: limit)
        return String(text[..<end])
    }
}
