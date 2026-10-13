import AnySSHCore
import CryptoKit
import Foundation
import Testing

@testable import FileTransfer

@Suite struct ImagePasteUploaderTests {
    private let root = "/home/me/.cache/anyssh/paste"
    private let moment = Date(timeIntervalSince1970: 1_760_364_153.5)

    @Test func uploadsIntoThePasteDirectoryAndReturnsTheRemotePath() async throws {
        let image = try PastedImageFixtures.png(width: 8, height: 8)
        let transport = ScriptedUploadTransport(root: root, payload: image.data)
        let uploader = ImagePasteUploader(connection: transport, now: { [moment] in moment })

        let path = try await uploader.upload(image)

        #expect(path == root + "/paste-20251013-140233-500.png")
        let commands = await transport.commands
        #expect(commands.first == LoginShellWrapper.wrap(ImagePasteDestination.prepareScript))
        let upload = await transport.uploadCommands
        #expect(
            upload == [
                SSHBlobUploader.uploadCommand(temporary: path + ".anyssh-partial", destination: path)
            ])
        #expect(await transport.uploadedBytes == image.data)
    }

    @Test func removesTheLocalStagingCopy() async throws {
        let image = try PastedImageFixtures.png(width: 8, height: 8)
        let staging = FileManager.default.temporaryDirectory
            .appending(path: "anyssh-paste-staging-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }
        let transport = ScriptedUploadTransport(root: root, payload: image.data)

        _ = try await ImagePasteUploader(connection: transport, stagingDirectory: staging)
            .upload(image)

        #expect(try FileManager.default.contentsOfDirectory(atPath: staging.path()).isEmpty)
    }

    @Test func aMismatchedDigestFailsTheUpload() async throws {
        let image = try PastedImageFixtures.png(width: 8, height: 8)
        let transport = ScriptedUploadTransport(root: root, payload: Data("other".utf8))

        await #expect(throws: UploadError.verificationFailed) {
            _ = try await ImagePasteUploader(connection: transport).upload(image)
        }
    }

    #if os(macOS)
    @Test func theUploadCommandSurvivesSpacesAndCleansUpOnFailure() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "anyssh upload \(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let destination = directory.appending(path: "My Photo.png").path(percentEncoded: false)
        let temporary = destination + ".anyssh-partial"
        let missing = directory.appending(path: "missing/My Photo.png").path(percentEncoded: false)

        let landed = try run(
            SSHBlobUploader.uploadCommand(temporary: temporary, destination: destination),
            stdin: Data("pixels".utf8)
        )
        let failed = try run(
            SSHBlobUploader.uploadCommand(temporary: temporary, destination: missing),
            stdin: Data("pixels".utf8)
        )

        #expect(landed == 0)
        #expect(FileManager.default.contents(atPath: destination) == Data("pixels".utf8))
        #expect(failed != 0)
        #expect(!FileManager.default.fileExists(atPath: temporary))
    }

    private func run(_ command: String, stdin: Data) throws -> Int32 {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.arguments = ["-c", command]
        process.environment = ["SHELL": "/bin/sh", "PATH": "/usr/bin:/bin"]
        let input = Pipe()
        process.standardInput = input
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try process.run()
        try input.fileHandleForWriting.write(contentsOf: stdin)
        try input.fileHandleForWriting.close()
        process.waitUntilExit()
        return process.terminationStatus
    }
    #endif
}

private actor ScriptedUploadTransport: BlobUploadTransport {
    private let root: String
    private let payload: Data
    private(set) var commands: [String] = []
    private(set) var uploadCommands: [String] = []
    private(set) var uploadedBytes = Data()

    init(root: String, payload: Data) {
        self.root = root
        self.payload = payload
    }

    func execute(_ command: String) async throws -> Data {
        commands.append(command)
        guard command.hasPrefix("wc -c") else { return Data("motd\n\(root)".utf8) }
        let digest = SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
        return Data("\(payload.count)\n\(digest)  file\n".utf8)
    }

    func uploadFile(_ file: URL, command: String) async throws {
        uploadCommands.append(command)
        uploadedBytes = try Data(contentsOf: file)
    }
}
