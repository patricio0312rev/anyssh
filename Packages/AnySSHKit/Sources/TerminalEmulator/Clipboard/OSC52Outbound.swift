import Foundation

public enum OSC52Outbound: Sendable {
    public static func chunks(
        for text: String,
        selection: String = OSC52Limits.defaultSelection,
        chunkBytes: Int = OSC52Limits.transportChunkBytes
    ) -> [[UInt8]] {
        let sequence = OSC52Sequence.write(text: text, selection: selection)
        let limit = max(1, chunkBytes)
        guard sequence.count > limit else { return [sequence] }

        var parts: [[UInt8]] = []
        parts.reserveCapacity((sequence.count + limit - 1) / limit)
        var index = sequence.startIndex
        while index < sequence.endIndex {
            let end =
                sequence.index(index, offsetBy: limit, limitedBy: sequence.endIndex) ?? sequence.endIndex
            parts.append(Array(sequence[index..<end]))
            index = end
        }
        return parts
    }

    public static func sequence(
        for text: String,
        selection: String = OSC52Limits.defaultSelection
    ) -> [UInt8] {
        OSC52Sequence.write(text: text, selection: selection)
    }
}
