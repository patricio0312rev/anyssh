import Foundation

public enum JSONNode: Equatable, Sendable {
    case object([(key: String, value: JSONNode)])
    case array([JSONNode])
    case string(String)
    case number(String)
    case boolean(Bool)
    case null

    public static func == (lhs: JSONNode, rhs: JSONNode) -> Bool {
        switch (lhs, rhs) {
        case (.object(let left), .object(let right)):
            left.count == right.count
                && zip(left, right).allSatisfy { $0.key == $1.key && $0.value == $1.value }
        case (.array(let left), .array(let right)): left == right
        case (.string(let left), .string(let right)): left == right
        case (.number(let left), .number(let right)): left == right
        case (.boolean(let left), .boolean(let right)): left == right
        case (.null, .null): true
        default: false
        }
    }

    public var childCount: Int {
        switch self {
        case .object(let children): children.count
        case .array(let children): children.count
        default: 0
        }
    }
}
