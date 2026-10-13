public protocol ClipboardContentSource: Sendable {
    func contentKinds() -> ClipboardContentKinds
    func readText() -> String?
    func readImage() -> PastedImage?
}
