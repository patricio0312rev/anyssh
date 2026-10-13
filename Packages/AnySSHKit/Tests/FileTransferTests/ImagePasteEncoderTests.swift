import AnySSHCore
import Foundation
import Testing

@testable import FileTransfer

@Suite struct ImagePasteEncoderTests {
    private let small = ImagePasteLimits(maxBytes: 200_000, maxPixelDimension: 64, jpegQualities: [0.8, 0.4])

    @Test func anImageInsideTheLimitsIsSentByteForByte() throws {
        let image = try PastedImageFixtures.png(width: 40, height: 20)

        #expect(try ImagePasteEncoder.fit(image, limits: small) == image)
    }

    @Test func aTallScreenshotShrinksToTheLongEdgeAndStaysPNG() throws {
        let image = try PastedImageFixtures.png(width: 50, height: 200)

        let fitted = try ImagePasteEncoder.fit(image, limits: small)
        let size = try #require(PastedImageFixtures.pixelSize(of: fitted))

        #expect(fitted.format == .png)
        #expect(size.height == 64)
        #expect(size.width == 16)
    }

    @Test func aPNGThatStaysHeavyFallsBackToJPEG() throws {
        let image = try PastedImageFixtures.png(width: 64, height: 64, noisy: true)
        let tight = ImagePasteLimits(
            maxBytes: image.data.count / 2, maxPixelDimension: 64, jpegQualities: [0.8, 0.5, 0.2])

        let fitted = try ImagePasteEncoder.fit(image, limits: tight)

        #expect(fitted.format == .jpeg)
        #expect(fitted.data.count <= tight.maxBytes)
    }

    @Test func aJPEGNeverComesBackAsPNG() throws {
        let image = try PastedImageFixtures.jpeg(width: 200, height: 100)

        let fitted = try ImagePasteEncoder.fit(image, limits: small)

        #expect(fitted.format == .jpeg)
        #expect(PastedImageFixtures.pixelSize(of: fitted)?.width == 64)
    }

    @Test func anImageNoQualityCanSaveIsRefused() throws {
        let image = try PastedImageFixtures.png(width: 64, height: 64, noisy: true)
        let impossible = ImagePasteLimits(maxBytes: 10, maxPixelDimension: 64, jpegQualities: [0.1])

        #expect(throws: ImagePasteEncoder.Failure.tooLarge) {
            try ImagePasteEncoder.fit(image, limits: impossible)
        }
    }

    @Test func bytesThatAreNotAnImageAreRefused() {
        let garbage = PastedImage(data: Data("not an image".utf8), format: .png)

        #expect(throws: ImagePasteEncoder.Failure.unreadable) {
            try ImagePasteEncoder.fit(garbage, limits: small)
        }
    }
}
