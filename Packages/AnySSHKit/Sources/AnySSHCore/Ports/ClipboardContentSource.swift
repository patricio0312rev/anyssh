import Foundation

public protocol ClipboardContentSource: Sendable {
    @MainActor func contentKinds() -> ClipboardContentKinds
    @MainActor func readText() -> String?
    @MainActor func readImage() -> Data?
}
