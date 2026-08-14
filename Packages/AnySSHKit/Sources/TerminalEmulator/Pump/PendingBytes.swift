struct PendingBytes {
    private static let empty = [UInt8]()[...]
    private static let compactionThreshold = 32

    private var chunks: [ArraySlice<UInt8>] = []
    private var firstIndex = 0

    private(set) var count = 0

    var isEmpty: Bool {
        count == 0
    }

    mutating func append(_ bytes: ArraySlice<UInt8>) {
        guard !bytes.isEmpty else { return }
        chunks.append(bytes)
        count += bytes.count
    }

    func peek(limit: Int) -> ArraySlice<UInt8> {
        let wanted = min(limit, count)
        guard wanted > 0 else { return Self.empty }

        let head = chunks[firstIndex]
        guard head.count < wanted else { return head.prefix(wanted) }

        var buffer = [UInt8]()
        buffer.reserveCapacity(wanted)
        var index = firstIndex
        while buffer.count < wanted {
            buffer.append(contentsOf: chunks[index].prefix(wanted - buffer.count))
            index += 1
        }
        return buffer[...]
    }

    mutating func commit(_ byteCount: Int) {
        var remaining = min(byteCount, count)
        count -= remaining

        while remaining > 0 {
            let head = chunks[firstIndex]
            guard head.count > remaining else {
                remaining -= head.count
                chunks[firstIndex] = Self.empty
                firstIndex += 1
                continue
            }
            chunks[firstIndex] = head.dropFirst(remaining)
            remaining = 0
        }

        guard firstIndex >= Self.compactionThreshold || firstIndex == chunks.count else { return }
        chunks.removeFirst(firstIndex)
        firstIndex = 0
    }
}
