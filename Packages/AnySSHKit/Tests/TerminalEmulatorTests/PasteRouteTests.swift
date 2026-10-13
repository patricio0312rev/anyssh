import AnySSHCore
import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct PasteRouteTests {
    private let shot = PastedImage(data: Data([0x89, 0x50, 0x4E, 0x47]), format: .png)

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

    @Test func anUnreadableImageFallsBackToItsText() {
        let source = ScriptedContentSource(
            kinds: ClipboardContentKinds(hasText: true, hasImage: true),
            text: "caption"
        )

        #expect(PasteRoute.resolve(from: source) == .text("caption"))
    }

    @Test func contentThatCannotBeReadIsADenial() {
        let source = ScriptedContentSource(kinds: ClipboardContentKinds(hasText: true, hasImage: true))

        #expect(PasteRoute.resolve(from: source) == .denied)
    }

    @Test func anEmptyImageIsNotPasted() {
        let source = ScriptedContentSource(image: PastedImage(data: Data(), format: .png))

        #expect(PasteRoute.resolve(from: source) == .denied)
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
    private let image: PastedImage?
    private(set) var textReads = 0
    private(set) var imageReads = 0

    init(kinds: ClipboardContentKinds? = nil, text: String? = nil, image: PastedImage? = nil) {
        self.kinds = kinds ?? ClipboardContentKinds(hasText: text != nil, hasImage: image != nil)
        self.text = text
        self.image = image
    }

    func contentKinds() -> ClipboardContentKinds { kinds }

    func readText() -> String? {
        textReads += 1
        return text
    }

    func readImage() -> PastedImage? {
        imageReads += 1
        return image
    }
}
