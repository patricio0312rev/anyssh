import Foundation

public struct JSONFlatRow: Identifiable {
    public enum Kind: Equatable, Sendable {
        case object
        case array
        case value
    }

    public static let summaryLimit = 60

    public let id: UUID
    public let depth: Int
    public let key: String?
    public let kind: Kind
    public let summary: String
    public let childCount: Int
    public let node: JSONNode
    public var expanded: Bool

    public var isExpandable: Bool {
        kind != .value && childCount > 0
    }

    static func root(_ node: JSONNode) -> JSONFlatRow {
        JSONFlatRow(
            id: UUID(),
            depth: 0,
            key: nil,
            kind: kind(of: node),
            summary: summary(of: node),
            childCount: node.childCount,
            node: node,
            expanded: false
        )
    }

    static func children(of node: JSONNode, at depth: Int) -> [JSONFlatRow] {
        switch node {
        case .object(let children):
            return children.map { pair in
                row(key: pair.key, node: pair.value, depth: depth)
            }
        case .array(let children):
            return children.enumerated().map { index, child in
                row(key: "[\(index)]", node: child, depth: depth)
            }
        default:
            return []
        }
    }

    private static func row(key: String, node: JSONNode, depth: Int) -> JSONFlatRow {
        JSONFlatRow(
            id: UUID(),
            depth: depth,
            key: key,
            kind: kind(of: node),
            summary: summary(of: node),
            childCount: node.childCount,
            node: node,
            expanded: false
        )
    }

    private static func kind(of node: JSONNode) -> Kind {
        switch node {
        case .object: .object
        case .array: .array
        default: .value
        }
    }

    private static func summary(of node: JSONNode) -> String {
        switch node {
        case .object(let children): "\(children.count) \(children.count == 1 ? "key" : "keys")"
        case .array(let children): "\(children.count) \(children.count == 1 ? "item" : "items")"
        case .string(let value): quoted(value)
        case .number(let raw): raw
        case .boolean(let value): value ? "true" : "false"
        case .null: "null"
        }
    }

    private static func quoted(_ value: String) -> String {
        guard value.count > summaryLimit else { return "\"\(value)\"" }
        return "\"\(value.prefix(summaryLimit))…\""
    }
}
