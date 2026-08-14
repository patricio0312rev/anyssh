import Foundation

@testable import AnySSHCore

enum Framing {
    static let nonce = fixed("0123456789abcdef0123456789abcdef")
    static let nearMissNonce = fixed("0123456789abcdef0123456789abcdee")

    static func fixed(_ hex: String) -> BatchNonce {
        guard let nonce = BatchNonce(hex: hex) else {
            preconditionFailure("not a batch tag: \(hex)")
        }
        return nonce
    }

    static func record(_ text: String, nonce: BatchNonce = Framing.nonce) -> Data {
        Data("\n--\(nonce.hex)--\(text)\n".utf8)
    }

    static func section(
        _ index: Int,
        _ body: Data,
        exit: Int32,
        length: Int? = nil,
        nonce: BatchNonce = Framing.nonce
    ) -> Data {
        record("R\(index):\(length ?? body.count):\(exit)", nonce: nonce) + body
    }

    static func end(_ count: Int) -> Data { record("Z\(count)") }

    static func response(_ bodies: [(body: Data, exit: Int32)], preamble: Data = Data()) -> Data {
        bodies.enumerated()
            .reduce(into: preamble) { response, entry in
                response += section(entry.offset, entry.element.body, exit: entry.element.exit)
            } + end(bodies.count)
    }

    static func batch(_ labels: [String]) -> RemoteBatch {
        RemoteBatch(commands: labels.map { RemoteCommand(label: $0, arguments: ["git", $0]) })
    }

    static func parse(_ response: Data, _ batch: RemoteBatch) throws -> BatchResponse {
        try BatchResponseParser(nonce: nonce, batch: batch).parse(response)
    }

    static func bytes(_ text: String) -> Data { Data(text.utf8) }
}
