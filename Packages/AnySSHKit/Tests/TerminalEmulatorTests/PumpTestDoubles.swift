import AnySSHCore
import CryptoKit

@testable import TerminalEmulator

@MainActor
final class RecordingTarget {
    private(set) var sliceLengths: [Int] = []
    private var digest = StreamDigest()
    private var held: CheckedContinuation<Void, Never>?
    private var stallsFrom: Int?

    var receivedBytes: Int {
        sliceLengths.reduce(0, +)
    }

    func stall(fromSlice index: Int) {
        stallsFrom = index
    }

    func release() {
        stallsFrom = nil
        held?.resume()
        held = nil
    }

    func finalizedDigest() -> SHA256Digest {
        digest.finalized()
    }

    func receive(_ bytes: ArraySlice<UInt8>) async {
        sliceLengths.append(bytes.count)
        digest.absorb(bytes)
        guard let stallsFrom, sliceLengths.count >= stallsFrom else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            held = continuation
        }
    }

    func pump(configuration: PumpConfiguration = .default) -> OutputPump {
        OutputPump(configuration: configuration) { [self] bytes in await receive(bytes) }
    }
}

@MainActor
final class CountingEngine: TerminalEngine {
    nonisolated static let bytesPerPrompt = 1_500

    private(set) var feedCount = 0
    private(set) var fedBytes = 0
    private(set) var titlesEmitted = 0
    private var delegate: (any TerminalEngineDelegate)?
    private let metadata: TerminalMetadataCoalescer?

    let size = TerminalSize.standard

    init(metadata: TerminalMetadataCoalescer? = nil) {
        self.metadata = metadata
    }

    func setDelegate(_ delegate: any TerminalEngineDelegate) {
        self.delegate = delegate
    }

    func feed(_ bytes: ArraySlice<UInt8>) {
        feedCount += 1
        fedBytes += bytes.count
        guard let metadata else { return }
        while titlesEmitted < fedBytes / Self.bytesPerPrompt {
            titlesEmitted += 1
            metadata.record(title: "prompt-\(titlesEmitted)")
        }
    }

    func resize(to size: TerminalSize) {}

    func setScrollbackLimit(_ lines: Int) {}
}

actor AcceptedCounter {
    private(set) var count = 0

    func record() {
        count += 1
    }
}

@MainActor
final class MetadataRecorder {
    private(set) var deliveries: [TerminalMetadata] = []

    func record(_ metadata: TerminalMetadata) {
        deliveries.append(metadata)
    }
}
