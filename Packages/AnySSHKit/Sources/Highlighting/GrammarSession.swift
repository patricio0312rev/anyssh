import AnySSHCore
import Foundation
import SwiftTreeSitter
import TreeSitter

final class GrammarSession {
    private let parser: OpaquePointer
    private let query: OpaquePointer
    private let codes: [UInt8?]

    init?(grammar: TreeSitterGrammar) {
        let language = grammar.language.tsLanguage

        guard let parser = ts_parser_new() else { return nil }
        guard ts_parser_set_language(parser, language) else {
            ts_parser_delete(parser)
            return nil
        }

        var errorOffset: UInt32 = 0
        var errorType = TSQueryErrorNone
        let source = Array(grammar.querySource.utf8)
        let compiled = source.withUnsafeBufferPointer { buffer -> OpaquePointer? in
            buffer.baseAddress?.withMemoryRebound(to: CChar.self, capacity: buffer.count) {
                ts_query_new(language, $0, UInt32(buffer.count), &errorOffset, &errorType)
            }
        }
        guard let query = compiled else {
            ts_parser_delete(parser)
            return nil
        }

        self.parser = parser
        self.query = query
        self.codes = (0..<Int(ts_query_capture_count(query))).map { id -> UInt8? in
            var length: UInt32 = 0
            guard let name = ts_query_capture_name_for_id(query, UInt32(id), &length) else {
                return nil
            }
            return TokenScope(rawValue: String(cString: name)).flatMap(TokenPainter.code(for:))
        }
    }

    deinit {
        ts_query_delete(query)
        ts_parser_delete(parser)
    }

    func captures(in blob: String) -> [TokenPainter.Capture]? {
        guard let data = blob.data(using: .utf16LittleEndian) else { return nil }

        let tree = data.withUnsafeBytes { raw -> OpaquePointer? in
            guard let base = raw.baseAddress else { return nil }
            return ts_parser_parse_string_encoding(
                parser,
                nil,
                base.assumingMemoryBound(to: CChar.self),
                UInt32(raw.count),
                TSInputEncodingUTF16LE
            )
        }
        guard let tree else { return nil }
        defer { ts_tree_delete(tree) }

        guard let cursor = ts_query_cursor_new() else { return nil }
        defer { ts_query_cursor_delete(cursor) }
        ts_query_cursor_exec(cursor, query, ts_tree_root_node(tree))

        var captures: [TokenPainter.Capture] = []
        captures.reserveCapacity(data.count / 24)
        var match = TSQueryMatch(id: 0, pattern_index: 0, capture_count: 0, captures: nil)

        while ts_query_cursor_next_match(cursor, &match) {
            guard let buffer = match.captures else { continue }
            for slot in 0..<Int(match.capture_count) {
                let capture = buffer[slot]
                guard let code = codes[Int(capture.index)] else { continue }
                let lower = Int(ts_node_start_byte(capture.node)) / 2
                let upper = Int(ts_node_end_byte(capture.node)) / 2
                guard lower < upper else { continue }
                captures.append(
                    TokenPainter.Capture(
                        lowerBound: lower,
                        upperBound: upper,
                        patternIndex: Int(match.pattern_index),
                        code: code
                    )
                )
            }
        }
        return captures
    }
}
