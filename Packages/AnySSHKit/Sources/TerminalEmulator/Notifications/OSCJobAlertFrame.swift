import Foundation

enum OSCJobAlertFrame {
    struct Parsed: Equatable, Sendable {
        let code: Int
        let payload: ArraySlice<UInt8>
    }

    static func parse(_ bytes: ArraySlice<UInt8>) -> Parsed? {
        let introducer: [UInt8] = [0x1b, UInt8(ascii: "]")]
        guard
            let start = bytes.indices.first(where: { index in
                guard bytes[index] == 0x1b else { return false }
                let next = bytes.index(after: index)
                return next < bytes.endIndex && bytes[next] == UInt8(ascii: "]")
            })
        else { return nil }
        var body = bytes[start...]
        guard body.starts(with: introducer) else { return nil }
        body = body.dropFirst(introducer.count)

        var end = body.endIndex
        for index in body.indices {
            if body[index] == 0x07 || body[index] == 0x1b {
                end = index
                break
            }
        }
        guard end > body.startIndex else { return nil }
        body = body[body.startIndex..<end]

        guard let semi = body.firstIndex(of: UInt8(ascii: ";")) else { return nil }
        let codeBytes = body[body.startIndex..<semi]
        guard let code = Int(String(decoding: codeBytes, as: UTF8.self)) else { return nil }
        return Parsed(code: code, payload: body[body.index(after: semi)...])
    }
}
