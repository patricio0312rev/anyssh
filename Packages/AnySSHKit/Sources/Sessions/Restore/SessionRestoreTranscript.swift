import AnySSHCore
import CryptoKit
import Foundation

public enum SessionRestoreTranscript {
    public static func tail(of dump: String, maxLines: Int) -> [String] {
        guard maxLines > 0 else { return [] }
        var lines = dump.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        if dump.hasSuffix("\n") && lines.last == "" {
            lines.removeLast()
        }
        return Array(lines.suffix(maxLines))
    }

    public static func joined(_ lines: [String]) -> String {
        lines.joined(separator: "\n")
    }

    public static func digest(_ lines: [String]) -> String {
        let data = Data(joined(lines).utf8)
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    @MainActor
    public static func restore(_ lines: [String], into engine: any TerminalEngine) {
        let bounded = tail(of: joined(lines), maxLines: SessionRestorePolicy.persistedTailLines)
        engine.feed(ArraySlice(joined(bounded).utf8))
    }
}
