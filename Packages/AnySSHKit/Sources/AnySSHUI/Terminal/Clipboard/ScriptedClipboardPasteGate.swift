public struct ScriptedClipboardPasteGate: ClipboardPasteGate, Sendable {
    private let access: ClipboardPasteAccess

    public init(_ access: ClipboardPasteAccess) {
        self.access = access
    }

    public init(text: String) {
        self.access = text.isEmpty ? .empty : .allowed(text)
    }

    public func requestPaste() async -> ClipboardPasteAccess {
        access
    }
}
