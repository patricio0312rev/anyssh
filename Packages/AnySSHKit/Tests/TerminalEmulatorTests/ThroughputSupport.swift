import CryptoKit
import Darwin
import Fixtures
import Foundation
import os

@testable import TerminalEmulator

@MainActor
final class ThroughputDrainTarget {
    private var hasher = SHA256()
    private var sentInput: ContinuousClock.Instant?
    private var inputLatencies = [Double]()
    private let signposter = OSSignposter(subsystem: "com.patricio0312rev.anyssh", category: "throughput")
    private(set) var bytes = 0
    private(set) var longestBlockMilliseconds = 0.0
    private(set) var presentedFrames = 0
    private(set) var droppedFrames = 0
    private(set) var inputEchoCount = 0

    func receive(_ bytes: ArraySlice<UInt8>) {
        let started = ContinuousClock.now
        let state = signposter.beginInterval("main-thread-block")
        bytes.withUnsafeBytes { hasher.update(bufferPointer: $0) }
        self.bytes += bytes.count
        presentedFrames += 1
        if let sentInput {
            inputLatencies.append(milliseconds(sentInput.duration(to: .now)))
            self.sentInput = nil
            inputEchoCount += 1
        }
        let elapsed = milliseconds(started.duration(to: .now))
        longestBlockMilliseconds = max(longestBlockMilliseconds, elapsed)
        signposter.endInterval("main-thread-block", state)
    }

    func armInput(at instant: ContinuousClock.Instant) {
        sentInput = instant
    }

    func checksum() -> String {
        hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func inputEchoP99Milliseconds() -> Double {
        guard !inputLatencies.isEmpty else { return .infinity }
        let sorted = inputLatencies.sorted()
        return sorted[min(sorted.count - 1, sorted.count * 99 / 100)]
    }

    var droppedFramePercentage: Double {
        let total = presentedFrames + droppedFrames
        return total == 0 ? 0 : Double(droppedFrames) / Double(total) * 100
    }

    private func milliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1_000
            + Double(duration.components.attoseconds) / 1e15
    }
}

struct ThroughputFixtureInput: Sendable {
    let bytes: [UInt8]
    let source: String

    static func yes() -> ThroughputFixtureInput {
        let url = FixtureBundle.url("terminal/yes-flood.bin")
        if let bytes = try? Array(Data(contentsOf: url)), !bytes.isEmpty {
            return ThroughputFixtureInput(bytes: bytes, source: "recorded E3 fixture")
        }
        return ThroughputFixtureInput(
            bytes: Array(repeating: UInt8(ascii: "y"), count: 64 * 1024),
            source: "synthetic host fallback; E3 fixture absent"
        )
    }
}

enum ThroughputTier: String, Sendable {
    case hostE1
    case simulatorE2
    case device

    static var current: ThroughputTier {
        let environment = ProcessInfo.processInfo.environment
        if environment["SIMULATOR_DEVICE_NAME"] != nil { return .simulatorE2 }
        if environment["ANYSSH_DEVICE_UDID"] != nil { return .device }
        return .hostE1
    }
}

func residentMemoryBytes() -> Int {
    var usage = rusage()
    getrusage(RUSAGE_SELF, &usage)
    return Int(usage.ru_maxrss)
}

enum ThroughputArtifact {
    static func write(
        tier: ThroughputTier,
        sustained: Double,
        peakResidentBytes: Int,
        longestBlockMilliseconds: Double,
        droppedFramePercentage: Double,
        inputEchoP99Milliseconds: Double
    ) -> URL? {
        let root = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let directory = root.appending(path: ".build/artifacts", directoryHint: .isDirectory)
        let url = directory.appending(path: "terminal-throughput-\(tier.rawValue).json")
        let values: [String: Any] = [
            "tier": tier.rawValue,
            "sustainedMBps": sustained,
            "peakResidentBytes": peakResidentBytes,
            "longestMainThreadBlockMilliseconds": longestBlockMilliseconds,
            "droppedFramePercentage": droppedFramePercentage,
            "inputEchoP99Milliseconds": inputEchoP99Milliseconds,
        ]
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONSerialization.data(withJSONObject: values, options: [.sortedKeys])
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}

func settled(
    _ target: ThroughputDrainTarget,
    expectedBytes: Int,
    turns: Int = 100_000
) async -> Bool {
    for _ in 0..<turns {
        if await MainActor.run(body: { target.bytes }) >= expectedBytes { return true }
        await Task.yield()
    }
    return false
}
