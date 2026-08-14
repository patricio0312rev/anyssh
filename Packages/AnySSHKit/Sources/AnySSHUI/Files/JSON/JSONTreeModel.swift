import Foundation

public struct JSONTreeModel {
    public private(set) var rows: [JSONFlatRow]

    public init(root: JSONNode) {
        rows = [JSONFlatRow.root(root)]
    }

    public var visibleRowCount: Int { rows.count }

    public func row(at index: Int) -> JSONFlatRow {
        rows[index]
    }

    private func index(of id: UUID) -> Int? {
        rows.firstIndex { $0.id == id }
    }

    public mutating func toggle(_ id: UUID) {
        guard let index = index(of: id) else { return }
        if rows[index].expanded {
            collapse(id)
        } else {
            expand(id)
        }
    }

    public mutating func expand(_ id: UUID) {
        guard let index = index(of: id) else { return }
        let row = rows[index]
        guard !row.expanded, row.isExpandable else { return }
        rows.insert(
            contentsOf: JSONFlatRow.children(of: row.node, at: row.depth + 1),
            at: index + 1
        )
        rows[index].expanded = true
    }

    public mutating func collapse(_ id: UUID) {
        guard let index = index(of: id), rows[index].expanded else { return }
        let depth = rows[index].depth
        var end = index + 1
        while end < rows.count, rows[end].depth > depth { end += 1 }
        rows.removeSubrange((index + 1)..<end)
        rows[index].expanded = false
    }
}
