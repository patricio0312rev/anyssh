import Foundation

struct JSONParser {
    let bytes: [UInt8]
    var offset = 0

    var isAtEnd: Bool { offset >= bytes.count }

    mutating func skipWhitespace() {
        while !isAtEnd,
            bytes[offset] == 0x20 || bytes[offset] == 0x09
                || bytes[offset] == 0x0A || bytes[offset] == 0x0D
        {
            offset += 1
        }
    }

    mutating func value() throws -> JSONNode {
        skipWhitespace()
        guard !isAtEnd else { throw JSONTextParser.Failure.unexpectedEnd }
        switch bytes[offset] {
        case 0x7B: return try object()
        case 0x5B: return try array()
        case 0x22: return .string(try string())
        case 0x74: return try literal("true", JSONNode.boolean(true))
        case 0x66: return try literal("false", JSONNode.boolean(false))
        case 0x6E: return try literal("null", .null)
        case 0x2D, 0x30...0x39: return .number(try number())
        default: throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
        }
    }

    mutating func object() throws -> JSONNode {
        offset += 1
        var children: [(key: String, value: JSONNode)] = []
        skipWhitespace()
        if consume(0x7D) { return .object(children) }
        while true {
            skipWhitespace()
            guard consume(0x22) else {
                throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
            }
            let key = try string(afterOpeningQuote: true)
            skipWhitespace()
            guard consume(0x3A) else {
                throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
            }
            let child = try value()
            children.append((key: key, value: child))
            skipWhitespace()
            if consume(0x7D) { return .object(children) }
            guard consume(0x2C) else {
                throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
            }
        }
    }

    mutating func array() throws -> JSONNode {
        offset += 1
        var children: [JSONNode] = []
        skipWhitespace()
        if consume(0x5D) { return .array(children) }
        while true {
            children.append(try value())
            skipWhitespace()
            if consume(0x5D) { return .array(children) }
            guard consume(0x2C) else {
                throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
            }
        }
    }

    mutating func number() throws -> String {
        let start = offset
        _ = consume(0x2D)
        if isAtEnd || bytes[offset] < 0x30 || bytes[offset] > 0x39 {
            throw JSONTextParser.Failure.invalidNumber(at: start)
        }
        if consume(0x30) {
        } else {
            while !isAtEnd, bytes[offset] >= 0x30, bytes[offset] <= 0x39 { offset += 1 }
        }
        if !isAtEnd, bytes[offset] == 0x2E {
            offset += 1
            guard !isAtEnd, bytes[offset] >= 0x30, bytes[offset] <= 0x39 else {
                throw JSONTextParser.Failure.invalidNumber(at: start)
            }
            while !isAtEnd, bytes[offset] >= 0x30, bytes[offset] <= 0x39 { offset += 1 }
        }
        if !isAtEnd, bytes[offset] == 0x65 || bytes[offset] == 0x45 {
            offset += 1
            if !isAtEnd, bytes[offset] == 0x2B || bytes[offset] == 0x2D { offset += 1 }
            guard !isAtEnd, bytes[offset] >= 0x30, bytes[offset] <= 0x39 else {
                throw JSONTextParser.Failure.invalidNumber(at: start)
            }
            while !isAtEnd, bytes[offset] >= 0x30, bytes[offset] <= 0x39 { offset += 1 }
        }
        return String(decoding: bytes[start..<offset], as: UTF8.self)
    }

    mutating func literal(_ word: String, _ node: JSONNode) throws -> JSONNode {
        let word = Array(word.utf8)
        guard bytes[offset...].starts(with: word) else {
            throw JSONTextParser.Failure.invalidCharacter(bytes[offset], at: offset)
        }
        offset += word.count
        return node
    }

    mutating func consume(_ byte: UInt8) -> Bool {
        guard !isAtEnd, bytes[offset] == byte else { return false }
        offset += 1
        return true
    }

    static func nibble(_ byte: UInt8) -> UInt8? {
        switch byte {
        case 0x30...0x39: byte - 0x30
        case 0x61...0x66: byte - 0x61 + 10
        case 0x41...0x46: byte - 0x41 + 10
        default: nil
        }
    }
}
