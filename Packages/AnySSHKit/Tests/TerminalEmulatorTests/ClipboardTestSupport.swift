import AnySSHCore

@testable import TerminalEmulator

final class RecordingPasteboard: ClipboardPasteboard, @unchecked Sendable {
    private(set) var value: String?
    private(set) var writes: [String] = []
    private(set) var reads = 0

    init(_ value: String? = nil) {
        self.value = value
    }

    func write(_ text: String) {
        value = text
        writes.append(text)
    }

    func read() -> String? {
        reads += 1
        return value
    }
}

final class RecordingTransportWrites: @unchecked Sendable {
    private(set) var chunks: [[UInt8]] = []

    var joined: [UInt8] { chunks.flatMap { $0 } }
    var isEmpty: Bool { chunks.isEmpty }
    var count: Int { chunks.count }

    func append(_ chunk: [UInt8]) {
        chunks.append(chunk)
    }
}

enum OSC52Fixtures {
    static func sequence(text: String, selection: String = "c") -> [UInt8] {
        OSC52Sequence.write(text: text, selection: selection)
    }

    static func sequence(base64: String, selection: String = "c") -> [UInt8] {
        Array("\u{1b}]52;\(selection);\(base64)\u{7}".utf8)
    }
}
