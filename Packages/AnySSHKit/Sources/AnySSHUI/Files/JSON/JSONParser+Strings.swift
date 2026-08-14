import Foundation

extension JSONParser {
    mutating func string(afterOpeningQuote: Bool = false) throws -> String {
        if !afterOpeningQuote {
            guard consume(0x22) else { throw JSONTextParser.Failure.invalidString(at: offset) }
        }
        var scalars: [Unicode.Scalar] = []
        while !isAtEnd {
            let byte = bytes[offset]
            offset += 1
            switch byte {
            case 0x22:
                return String(String.UnicodeScalarView(scalars))
            case 0x5C:
                let escape = try escapedScalar()
                if let high = escape, high.value >= 0xD800, high.value <= 0xDBFF {
                    guard let low = try escapedLowSurrogate() else {
                        throw JSONTextParser.Failure.invalidString(at: offset)
                    }
                    let combined = 0x10000 + (high.value - 0xD800) * 0x400 + (low.value - 0xDC00)
                    guard let scalar = Unicode.Scalar(combined) else {
                        throw JSONTextParser.Failure.invalidString(at: offset)
                    }
                    scalars.append(scalar)
                } else if let escape {
                    scalars.append(escape)
                }
            case 0x00...0x1F:
                throw JSONTextParser.Failure.invalidString(at: offset)
            default:
                if byte & 0x80 == 0 {
                    scalars.append(Unicode.Scalar(byte))
                } else {
                    scalars.append(contentsOf: try utf8Scalar(from: offset - 1))
                }
            }
        }
        throw JSONTextParser.Failure.unexpectedEnd
    }

    mutating func escapedScalar() throws -> Unicode.Scalar? {
        guard !isAtEnd else { throw JSONTextParser.Failure.unexpectedEnd }
        let byte = bytes[offset]
        offset += 1
        switch byte {
        case 0x22: return Unicode.Scalar(0x22)
        case 0x5C: return Unicode.Scalar(0x5C)
        case 0x2F: return Unicode.Scalar(0x2F)
        case 0x62: return Unicode.Scalar(0x08)
        case 0x66: return Unicode.Scalar(0x0C)
        case 0x6E: return Unicode.Scalar(0x0A)
        case 0x72: return Unicode.Scalar(0x0D)
        case 0x74: return Unicode.Scalar(0x09)
        case 0x75: return Unicode.Scalar(try hexQuad())
        default: throw JSONTextParser.Failure.invalidString(at: offset)
        }
    }

    mutating func escapedLowSurrogate() throws -> Unicode.Scalar? {
        guard !isAtEnd, bytes[offset] == 0x5C else { return nil }
        let saved = offset
        offset += 1
        guard !isAtEnd, bytes[offset] == 0x75 else {
            offset = saved
            return nil
        }
        let value = try hexQuad()
        guard value >= 0xDC00, value <= 0xDFFF else {
            offset = saved
            return nil
        }
        return Unicode.Scalar(value)
    }

    mutating func hexQuad() throws -> UInt32 {
        var value: UInt32 = 0
        for _ in 0..<4 {
            guard !isAtEnd, let nibble = Self.nibble(bytes[offset]) else {
                throw JSONTextParser.Failure.invalidString(at: offset)
            }
            value = value * 16 + UInt32(nibble)
            offset += 1
        }
        return value
    }

    mutating func utf8Scalar(from start: Int) throws -> [Unicode.Scalar] {
        let first = bytes[start]
        let length: Int
        if first & 0xE0 == 0xC0 {
            length = 2
        } else if first & 0xF0 == 0xE0 {
            length = 3
        } else if first & 0xF8 == 0xF0 {
            length = 4
        } else {
            throw JSONTextParser.Failure.invalidString(at: start)
        }
        guard start + length <= bytes.count else { throw JSONTextParser.Failure.unexpectedEnd }
        for index in (start + 1)..<(start + length) {
            guard bytes[index] & 0xC0 == 0x80 else {
                throw JSONTextParser.Failure.invalidString(at: index)
            }
        }
        offset = start + length
        return String(decoding: bytes[start..<(start + length)], as: UTF8.self)
            .unicodeScalars.map { $0 }
    }
}
