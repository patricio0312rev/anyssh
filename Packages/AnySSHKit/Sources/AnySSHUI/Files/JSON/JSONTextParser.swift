import Foundation

public enum JSONTextParser {
    public enum Failure: Error, Equatable, Sendable {
        case unexpectedEnd
        case invalidCharacter(UInt8, at: Int)
        case invalidString(at: Int)
        case invalidNumber(at: Int)
        case trailingContent(at: Int)
    }

    public static func parse(_ text: String) throws -> JSONNode {
        var parser = JSONParser(bytes: Array(text.utf8))
        parser.skipWhitespace()
        let node = try parser.value()
        parser.skipWhitespace()
        guard parser.isAtEnd else { throw Failure.trailingContent(at: parser.offset) }
        return node
    }
}
