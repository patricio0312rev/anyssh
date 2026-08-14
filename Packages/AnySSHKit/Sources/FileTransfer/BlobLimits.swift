import AnySSHCore

public enum BlobLimit: Sendable, Hashable {
    case diffSide
    case source
    case image
    case svg
    case video

    public var byteCount: Int {
        switch self {
        case .diffSide: 256 * 1024
        case .source: 2 * 1024 * 1024
        case .image: 25 * 1024 * 1024
        case .svg: 256 * 1024
        case .video: 50 * 1024 * 1024
        }
    }

    public init(intent: BlobIntent) {
        switch intent {
        case .diffSide: self = .diffSide
        case .source: self = .source
        case .image: self = .image
        case .svg: self = .svg
        case .video: self = .video
        }
    }
}
