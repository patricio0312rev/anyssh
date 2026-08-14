import Foundation

public enum FileContentCommand {
    public static let label = "file-content"
    public static let byteCap = 512 * 1024

    public static func batch(path: String, cap: Int = byteCap) -> RemoteBatch {
        RemoteBatch(commands: [
            RemoteCommand(
                label: label,
                arguments: ["sh", "-c", script(path: path, cap: max(1, cap))],
                byteCap: cap + 4096
            )
        ])
    }

    static func script(path: String, cap: Int) -> String {
        let quoted = ShellQuoting.singleQuote(path)
        return """
            __path=\(quoted)
            [ -f "$__path" ] || { printf 'error\\tnot-a-file\\n'; exit 0; }
            __size=$(wc -c < "$__path" 2>/dev/null | tr -d ' ')
            printf 'size\\t%s\\n' "${__size:-0}"
            printf 'content\\n'
            head -c \(cap) -- "$__path"
            """
    }

    public struct Content: Hashable, Sendable {
        public let bytes: Data
        public let byteCount: Int
        public var isTruncated: Bool { byteCount > bytes.count }
        public var isBinary: Bool { bytes.prefix(8000).contains(0) }
    }

    public enum Failure: Error, Equatable, Sendable {
        case notAFile
        case malformed
    }

    public static func parse(_ data: Data) throws -> Content {
        guard let contentRange = data.range(of: Data("content\n".utf8)) else {
            if data.starts(with: Data("error\tnot-a-file".utf8)) { throw Failure.notAFile }
            throw Failure.malformed
        }
        let header = String(decoding: data[..<contentRange.lowerBound], as: UTF8.self)
        let size =
            header
            .split(separator: "\n")
            .first { $0.hasPrefix("size\t") }
            .flatMap { Int($0.dropFirst(5)) }
        guard let size else { throw Failure.malformed }
        return Content(bytes: Data(data[contentRange.upperBound...]), byteCount: size)
    }
}
