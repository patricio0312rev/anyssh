struct LineIndex {
    private let starts: [Int]
    private let ends: [Int]

    let length: Int

    init(_ blob: String) {
        var starts: [Int] = []
        var ends: [Int] = []
        var offset = 0
        var lineStart = 0
        var contiguous = blob
        let byteCount = contiguous.utf8.count
        starts.reserveCapacity(byteCount / 32 + 1)
        ends.reserveCapacity(byteCount / 32 + 1)

        contiguous.withUTF8 { bytes in
            for byte in bytes {
                if byte == 0x0A {
                    starts.append(lineStart)
                    ends.append(offset)
                    lineStart = offset + 1
                }
                if byte & 0xC0 != 0x80 { offset += byte >= 0xF0 ? 2 : 1 }
            }
        }

        if lineStart < offset {
            starts.append(lineStart)
            ends.append(offset)
        }

        self.starts = starts
        self.ends = ends
        self.length = offset
    }

    var lineCount: Int { starts.count }

    func start(of line: Int) -> Int { starts[line] }

    func end(of line: Int) -> Int { ends[line] }
}
