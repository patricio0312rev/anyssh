import Foundation

public enum KeyMaterialParser {
    public static func parse(_ buffer: KeyMaterialBuffer) throws -> KeyMaterial {
        try buffer.withBytes { try describe(Array($0)) }
    }

    static func describe(_ bytes: [UInt8]) throws -> KeyMaterial {
        let lines = Armour.lines(of: bytes)
        guard lines.contains(where: { !$0.isEmpty }) else { throw KeyMaterialError.nothingToImport }
        guard let opening = Armour.opening(in: lines) else { throw refusal(for: lines) }

        let format = opening.format
        let closing = Array(format.endLine.utf8)
        guard let end = lines[opening.index...].dropFirst().firstIndex(of: closing) else {
            throw KeyMaterialError.truncated(format)
        }

        let block = Armour.block(in: lines[(opening.index + 1)..<end])
        guard let body = Armour.decode(block.body), !body.isEmpty else {
            throw KeyMaterialError.unreadable(format)
        }

        guard format != .openSSH else { return try OpenSSHPrivateKey.describe(body) }
        return try PEMPrivateKey.describe(format: format, headers: block.headers, body: body)
    }

    private static func refusal(for lines: [[UInt8]]) -> KeyMaterialError {
        if let algorithm = Armour.publicKeyAlgorithm(in: lines) {
            return .publicKeyOffered(algorithm)
        }
        let hasEnvelope = lines.contains { Armour.text($0).hasPrefix("-----BEGIN") }
        return hasEnvelope ? .unrecognisedEnvelope : .noEnvelope
    }
}

enum Armour {
    struct Block {
        let headers: [String: String]
        let body: [UInt8]
    }

    struct Opening {
        let index: Int
        let format: PrivateKeyFormat
    }

    static func lines(of bytes: [UInt8]) -> [[UInt8]] {
        bytes.split(separator: 0x0A, omittingEmptySubsequences: false).map(trimmed)
    }

    static func text(_ line: [UInt8]) -> String {
        String(decoding: line, as: UTF8.self)
    }

    static func opening(in lines: [[UInt8]]) -> Opening? {
        for (index, line) in lines.enumerated() {
            if let format = PrivateKeyFormat.allCases.first(where: {
                Array($0.beginLine.utf8) == line
            }) {
                return Opening(index: index, format: format)
            }
        }
        return nil
    }

    static func block(in lines: some Collection<[UInt8]>) -> Block {
        var headers: [String: String] = [:]
        var body: [UInt8] = []
        var inHeaders = true

        for line in lines {
            guard inHeaders else {
                body += line
                continue
            }
            let rendered = text(line)
            if rendered.isEmpty {
                inHeaders = false
            } else if let colon = rendered.firstIndex(of: ":") {
                let value = String(rendered[rendered.index(after: colon)...])
                headers[String(rendered[..<colon])] = value.trimmingCharacters(in: .whitespaces)
            } else {
                inHeaders = false
                body += line
            }
        }
        return Block(headers: headers, body: body)
    }

    static func decode(_ base64: [UInt8]) -> [UInt8]? {
        guard !base64.isEmpty, base64.count % 4 == 0 else { return nil }
        return Data(base64Encoded: Data(base64)).map(Array.init)
    }

    static func publicKeyAlgorithm(in lines: [[UInt8]]) -> PrivateKeyAlgorithm? {
        guard let first = lines.first(where: { !$0.isEmpty }) else { return nil }
        let rendered = text(first)
        guard !rendered.hasPrefix("---- BEGIN SSH2 PUBLIC KEY ----") else { return .unknown }

        let algorithm = PrivateKeyAlgorithm(wireName: String(rendered.prefix { $0 != " " }))
        return algorithm != .unknown && rendered.contains(" ") ? algorithm : nil
    }

    private static func trimmed(_ line: ArraySlice<UInt8>) -> [UInt8] {
        var slice = line
        while let first = slice.first, isBlank(first) { slice = slice.dropFirst() }
        while let last = slice.last, isBlank(last) { slice = slice.dropLast() }
        return Array(slice)
    }

    private static func isBlank(_ byte: UInt8) -> Bool {
        byte == 0x20 || byte == 0x09 || byte == 0x0D
    }
}
