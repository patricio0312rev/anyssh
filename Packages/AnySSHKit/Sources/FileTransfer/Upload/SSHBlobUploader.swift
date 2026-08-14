import AnySSHCore
import CryptoKit
import Foundation

public actor SSHBlobUploader: BlobUploader {
    private let connection: any BlobUploadTransport

    public init(connection: any BlobUploadTransport) {
        self.connection = connection
    }

    private func destinationRoot() async throws -> String {
        let probe =
            #"d="$HOME/Downloads"; [ -d "$d" ] || d="$HOME/.anyssh/uploads"; "#
            + #"mkdir -p -- "$d" && printf %s "$d""#
        let answer = try await connection.execute(LoginShellWrapper.wrap(probe))
        let root = String(decoding: answer, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .last { $0.hasPrefix("/") }
        guard let root, !root.isEmpty else { throw UploadError.verificationFailed }
        return root
    }

    public func upload(file: URL, to path: String) async throws -> BlobUploadResult {
        let (byteCount, digest) = try Self.digest(file)
        let destinationRoot = try await destinationRoot()
        let destination = destinationRoot + "/" + path
        let temporary = destination + ".anyssh-partial"
        let quotedTemporary = ShellQuoting.singleQuote(temporary)
        let quotedDestination = ShellQuoting.singleQuote(destination)
        let command =
            "trap 'rm -f -- \(quotedTemporary)' EXIT; cat > \(quotedTemporary) && mv -- \(quotedTemporary) \(quotedDestination)"
        try await connection.uploadFile(file, command: LoginShellWrapper.wrap(command))
        let verification = try await connection.execute(
            "wc -c < \(quotedDestination) 2>/dev/null; "
                + "(sha256sum \(quotedDestination) 2>/dev/null "
                + "|| shasum -a 256 \(quotedDestination) 2>/dev/null)"
        )
        let result = try VerificationParser.parse(verification, path: destination)
        guard result.byteCount == byteCount, result.sha256 == digest else {
            try? await connection.execute("rm -f -- \(quotedDestination)")
            throw UploadError.verificationFailed
        }
        return result
    }

    private static func digest(_ file: URL) throws -> (Int, String) {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var hash = SHA256()
        var count = 0
        while let data = try handle.read(upToCount: 64 * 1024), !data.isEmpty {
            hash.update(data: data)
            count += data.count
        }
        let digest = hash.finalize().map { String(format: "%02x", $0) }.joined()
        return (count, digest)
    }
}

enum VerificationParser {
    static func parse(_ data: Data, path: String) throws -> BlobUploadResult {
        let lines = String(decoding: data, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
        guard let count = lines.compactMap({ Int($0) }).first else {
            throw UploadError.verificationFailed
        }
        let digest = lines.flatMap { $0.split(separator: " ") }.first { token in
            token.count == 64 && token.allSatisfy(\.isHexDigit)
        }
        guard let digest else { throw UploadError.verificationFailed }
        return BlobUploadResult(path: path, byteCount: count, sha256: String(digest))
    }
}

public enum UploadError: Error, Sendable {
    case verificationFailed
}
