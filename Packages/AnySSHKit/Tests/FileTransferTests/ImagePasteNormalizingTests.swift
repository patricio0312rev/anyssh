import AnySSHCore
import CryptoKit
import Foundation
import Testing
import UniformTypeIdentifiers

@testable import FileTransfer

@Suite struct ImagePasteNormalizingTests {
    @Test func aPNGKeepsItsBytesAndFormat() throws {
        let data = try PastedImageFixtures.data(width: 8, height: 8, as: .png)

        #expect(try ImagePasteEncoder.image(from: data) == PastedImage(data: data, format: .png))
    }

    @Test func aJPEGKeepsItsBytesAndFormat() throws {
        let data = try PastedImageFixtures.data(width: 8, height: 8, as: .jpeg)

        #expect(try ImagePasteEncoder.image(from: data) == PastedImage(data: data, format: .jpeg))
    }

    @Test func anyOtherImageBecomesAJPEGOfTheSameSize() throws {
        let data = try PastedImageFixtures.data(width: 12, height: 6, as: .tiff)

        let image = try ImagePasteEncoder.image(from: data)
        let size = try #require(PastedImageFixtures.pixelSize(of: image))

        #expect(image.format == .jpeg)
        #expect(size.width == 12)
        #expect(size.height == 6)
    }

    @Test func bytesThatAreNotAnImageAreRefused() {
        #expect(throws: ImagePasteEncoder.Failure.unreadable) {
            try ImagePasteEncoder.image(from: Data("not an image".utf8))
        }
    }

    @Test func thePhotoUploadNormalizesBeforeSending() async throws {
        let data = try PastedImageFixtures.data(width: 8, height: 8, as: .tiff)
        let transport = NormalizingTransport()

        let path = try await ImagePasteUploader(connection: transport).upload(contentsOf: data)

        #expect(path.hasSuffix(".jpg"))
    }
}

private actor NormalizingTransport: BlobUploadTransport {
    private var uploaded = Data()

    func execute(_ command: String) async throws -> Data {
        guard command.hasPrefix("wc -c") else { return Data("/home/me/.cache/anyssh/paste".utf8) }
        let digest = SHA256.hash(data: uploaded).map { String(format: "%02x", $0) }.joined()
        return Data("\(uploaded.count)\n\(digest)  file\n".utf8)
    }

    func uploadFile(_ file: URL, command: String) async throws {
        uploaded = try Data(contentsOf: file)
    }
}
