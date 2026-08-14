import Foundation

public struct LFSDetector: Sendable {
    public init() {}

    public func isPointer(_ data: Data) -> Bool {
        guard data.count >= 110, data.count <= 200 else { return false }
        guard let text = String(data: data, encoding: .utf8) else { return false }
        return text.hasPrefix("version https://git-lfs.github.com/spec/v1")
    }
}
