public enum ClipboardPasteAccess: Equatable, Sendable {
    case allowed(String)
    case denied
    case empty
}

public protocol ClipboardPasteGate: Sendable {
    func requestPaste() async -> ClipboardPasteAccess
}
