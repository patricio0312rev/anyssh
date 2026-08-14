struct DERReader {
    struct Element {
        let tag: UInt8
        let contents: [UInt8]
    }

    private let bytes: [UInt8]
    private var offset: Int

    init(_ bytes: [UInt8]) {
        self.bytes = bytes
        offset = 0
    }

    mutating func next() -> Element? {
        guard offset + 2 <= bytes.count else { return nil }
        let tag = bytes[offset]
        offset += 1
        guard let length = length(), offset + length <= bytes.count else { return nil }
        defer { offset += length }
        return Element(tag: tag, contents: Array(bytes[offset..<offset + length]))
    }

    private mutating func length() -> Int? {
        guard offset < bytes.count else { return nil }
        let first = bytes[offset]
        offset += 1
        guard first & 0x80 != 0 else { return Int(first) }

        let count = Int(first & 0x7F)
        guard count > 0, count <= 4, offset + count <= bytes.count else { return nil }
        defer { offset += count }
        return bytes[offset..<offset + count].reduce(0) { $0 << 8 | Int($1) }
    }

    static func children(ofSequenceIn bytes: [UInt8]) -> [Element] {
        var outer = DERReader(bytes)
        guard let sequence = outer.next(), sequence.tag == tagSequence else { return [] }

        var inner = DERReader(sequence.contents)
        var elements: [Element] = []
        while let element = inner.next() {
            elements.append(element)
        }
        return elements
    }

    static let tagInteger: UInt8 = 0x02
    static let tagOctetString: UInt8 = 0x04
    static let tagObjectIdentifier: UInt8 = 0x06
    static let tagSequence: UInt8 = 0x30
}
