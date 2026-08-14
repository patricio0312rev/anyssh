import AnySSHCore

struct TokenPainter {
    struct Capture {
        let lowerBound: Int
        let upperBound: Int
        let patternIndex: Int
        let code: UInt8
    }

    private static let scopes = TokenScope.allCases
    private static let plainCode = UInt8(TokenScope.allCases.count)

    static func code(for scope: TokenScope) -> UInt8? {
        guard scope != .plain, let index = scopes.firstIndex(of: scope) else { return nil }
        return UInt8(index)
    }

    let index: LineIndex

    func paint(_ captures: consuming [Capture]) -> [LineTokens] {
        var ordered = captures
        ordered.sort { lhs, rhs in
            let left = lhs.upperBound - lhs.lowerBound
            let right = rhs.upperBound - rhs.lowerBound
            if left != right { return left > right }
            return lhs.patternIndex > rhs.patternIndex
        }

        var canvas = [UInt8](repeating: Self.plainCode, count: index.length)
        return canvas.withUnsafeMutableBufferPointer { buffer -> [LineTokens] in
            for capture in ordered {
                let upper = min(capture.upperBound, buffer.count)
                var offset = max(0, capture.lowerBound)
                while offset < upper {
                    buffer[offset] = capture.code
                    offset += 1
                }
            }
            return (0..<index.lineCount).map { LineTokens(spans: spans(buffer, line: $0)) }
        }
    }

    private func spans(_ canvas: UnsafeMutableBufferPointer<UInt8>, line: Int) -> [TokenSpan] {
        let start = index.start(of: line)
        let end = index.end(of: line)
        guard start < end else { return [] }

        var spans: [TokenSpan] = []
        var runStart = start
        var runCode = canvas[start]
        var offset = start + 1

        while offset < end {
            let code = canvas[offset]
            if code != runCode {
                append(&spans, code: runCode, from: runStart - start, to: offset - start)
                runStart = offset
                runCode = code
            }
            offset += 1
        }
        append(&spans, code: runCode, from: runStart - start, to: end - start)
        return spans
    }

    private func append(_ spans: inout [TokenSpan], code: UInt8, from: Int, to: Int) {
        guard code != Self.plainCode else { return }
        spans.append(TokenSpan(range: from..<to, scope: Self.scopes[Int(code)]))
    }
}
