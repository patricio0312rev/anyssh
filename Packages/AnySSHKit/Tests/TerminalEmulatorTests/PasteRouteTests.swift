import AnySSHCore
import Foundation
import Testing

@testable import TerminalEmulator

@MainActor
@Suite struct PasteRouteTests {
    private let shot = Data([0x89, 0x50, 0x4E, 0x47])

    @Test func anImageWinsOverTextSoScreenshotsUpload() {
        let source = ScriptedContentSource(text: "https://example.com/shot.png", image: shot)

        #expect(PasteRoute.resolve(from: source) == .image(shot))
        #expect(source.textReads == 0)
    }

    @Test func plainTextStaysText() {
        let source = ScriptedContentSource(text: "ls -la")

        #expect(PasteRoute.resolve(from: source) == .text("ls -la"))
        #expect(source.imageReads == 0)
    }

    @Test func anEmptyImageIsUnreadableEvenBesideText() {
        let source = ScriptedContentSource(text: "caption", image: Data())

        #expect(PasteRoute.resolve(from: source) == .unreadableImage)
        #expect(source.textReads == 0)
    }

    @Test func anImageThatCannotBeReadIsADenialNotItsText() {
        let source = ScriptedContentSource(
            kinds: ClipboardContentKinds(hasText: true, hasImage: true),
            text: "caption"
        )

        #expect(PasteRoute.resolve(from: source) == .denied)
        #expect(source.textReads == 0)
    }

    @Test func textThatCannotBeReadIsADenial() {
        let source = ScriptedContentSource(kinds: ClipboardContentKinds(hasText: true, hasImage: false))

        #expect(PasteRoute.resolve(from: source) == .denied)
    }

    @Test func anEmptyStringIsNothingToPaste() {
        let source = ScriptedContentSource(text: "")

        #expect(PasteRoute.resolve(from: source) == .empty)
    }

    @Test func nothingOnTheClipboardIsEmptyWithoutAnyRead() {
        let source = ScriptedContentSource()

        #expect(PasteRoute.resolve(from: source) == .empty)
        #expect(source.textReads == 0)
        #expect(source.imageReads == 0)
    }
}

private final class ScriptedContentSource: ClipboardContentSource, @unchecked Sendable {
    private let kinds: ClipboardContentKinds
    private let text: String?
    private let image: Data?
    private(set) var textReads = 0
    private(set) var imageReads = 0

    init(kinds: ClipboardContentKinds? = nil, text: String? = nil, image: Data? = nil) {
        self.kinds = kinds ?? ClipboardContentKinds(hasText: text != nil, hasImage: image != nil)
        self.text = text
        self.image = image
    }

    func contentKinds() -> ClipboardContentKinds { kinds }

    func readText() -> String? {
        textReads += 1
        return text
    }

    func readImage() -> Data? {
        imageReads += 1
        return image
    }
}
