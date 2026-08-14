import CryptoKit

struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func bytes(_ count: Int) -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(count)
        while output.count < count {
            withUnsafeBytes(of: next().littleEndian) { output.append(contentsOf: $0) }
        }
        output.removeLast(output.count - count)
        return output
    }

    mutating func chunkLengths(total: Int, upTo limit: Int) -> [Int] {
        var lengths: [Int] = []
        var remaining = total
        while remaining > 0 {
            let length = min(remaining, 1 + Int(next() % UInt64(limit)))
            lengths.append(length)
            remaining -= length
        }
        return lengths
    }
}

struct StreamDigest {
    private var hasher = SHA256()

    mutating func absorb(_ bytes: ArraySlice<UInt8>) {
        bytes.withUnsafeBytes { hasher.update(bufferPointer: $0) }
    }

    func finalized() -> SHA256Digest {
        hasher.finalize()
    }

    static func of(_ bytes: [UInt8]) -> SHA256Digest {
        var digest = StreamDigest()
        digest.absorb(bytes[...])
        return digest.finalized()
    }
}

func waitUntil(_ condition: () async -> Bool) async {
    while await !condition() {
        await Task.yield()
    }
}
