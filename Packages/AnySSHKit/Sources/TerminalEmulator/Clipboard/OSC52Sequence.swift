import Foundation

public enum OSC52Sequence: Sendable {
    private static let introducer: [UInt8] = [
        0x1b, UInt8(ascii: "]"), UInt8(ascii: "5"), UInt8(ascii: "2"),
    ]
    private static let bel: UInt8 = 0x07
    private static let st: [UInt8] = [0x1b, UInt8(ascii: "\\")]

    public static func write(text: String, selection: String = OSC52Limits.defaultSelection) -> [UInt8] {
        let encoded = Data(text.utf8).base64EncodedString()
        return prefix(selection: selection) + Array(encoded.utf8) + [bel]
    }

    public static func query(selection: String = OSC52Limits.defaultSelection) -> [UInt8] {
        prefix(selection: selection) + [UInt8(ascii: "?")] + [bel]
    }

    public static func prefix(selection: String) -> [UInt8] {
        introducer + [UInt8(ascii: ";")] + Array(selection.utf8) + [UInt8(ascii: ";")]
    }

    public static func parse(
        _ bytes: ArraySlice<UInt8>
    ) -> (selection: String, payload: ArraySlice<UInt8>)? {
        guard bytes.starts(with: introducer) else { return nil }
        var body = bytes.dropFirst(introducer.count)
        guard body.first == UInt8(ascii: ";") else { return nil }
        body = body.dropFirst()

        guard let selectionEnd = body.firstIndex(of: UInt8(ascii: ";")) else { return nil }
        let selectionBytes = body[body.startIndex..<selectionEnd]
        let selection =
            selectionBytes.isEmpty
            ? OSC52Limits.defaultSelection
            : (String(bytes: selectionBytes, encoding: .ascii) ?? OSC52Limits.defaultSelection)
        body = body[body.index(after: selectionEnd)...]

        if body.last == bel {
            return (selection, body.dropLast())
        }
        if body.count >= 2, body.suffix(2).elementsEqual(st) {
            return (selection, body.dropLast(2))
        }
        return nil
    }
}
