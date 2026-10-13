import Foundation

public struct PastedImage: Sendable, Hashable {
    public enum Format: String, Sendable, Hashable {
        case png
        case jpeg

        public var fileExtension: String {
            switch self {
            case .png: "png"
            case .jpeg: "jpg"
            }
        }
    }

    public let data: Data
    public let format: Format

    public init(data: Data, format: Format) {
        self.data = data
        self.format = format
    }
}
