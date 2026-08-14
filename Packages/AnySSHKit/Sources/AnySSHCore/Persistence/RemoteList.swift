import Foundation

public struct RemoteList: Hashable, Sendable {
    public private(set) var remotes: [Remote]

    public init(_ remotes: [Remote] = []) {
        self.remotes = Self.renumbered(Self.ordered(remotes))
    }

    public mutating func upsert(_ remote: Remote) {
        if let index = remotes.firstIndex(where: { $0.id == remote.id }) {
            var replacement = remote
            replacement.orderIndex = index
            remotes[index] = replacement
        } else {
            var appended = remote
            appended.orderIndex = remotes.count
            remotes.append(appended)
        }
    }

    public mutating func remove(_ id: RemoteID) {
        remotes.removeAll { $0.id == id }
        remotes = Self.renumbered(remotes)
    }

    public mutating func reorder(to order: [RemoteID]) {
        let rank = Dictionary(
            order.enumerated().map { ($0.element, $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
        let ranked = remotes.enumerated().sorted {
            let left = (rank[$0.element.id] ?? order.count, $0.offset)
            let right = (rank[$1.element.id] ?? order.count, $1.offset)
            return left < right
        }
        remotes = Self.renumbered(ranked.map(\.element))
    }

    public mutating func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let moved = source.compactMap { remotes.indices.contains($0) ? remotes[$0] : nil }
        guard !moved.isEmpty else { return }

        var rest = remotes
        for index in source.sorted(by: >) where rest.indices.contains(index) {
            rest.remove(at: index)
        }
        let target = max(destination, 0)
        let insertion = min(max(target - source.count(in: 0..<target), 0), rest.count)
        rest.insert(contentsOf: moved, at: insertion)
        remotes = Self.renumbered(rest)
    }

    private static func ordered(_ remotes: [Remote]) -> [Remote] {
        remotes.enumerated()
            .sorted { ($0.element.orderIndex, $0.offset) < ($1.element.orderIndex, $1.offset) }
            .map(\.element)
    }

    private static func renumbered(_ remotes: [Remote]) -> [Remote] {
        remotes.enumerated().map { offset, remote in
            var numbered = remote
            numbered.orderIndex = offset
            return numbered
        }
    }
}
