import AnySSHCore

public protocol ClipboardPasteboard: Sendable {
    func write(_ text: String)
    func read() -> String?
}
