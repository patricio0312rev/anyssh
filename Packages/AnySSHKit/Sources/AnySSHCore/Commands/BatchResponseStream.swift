import Foundation

struct BatchFrame: Hashable, Sendable {
    let index: Int
    let bytes: Data
    let exitCode: Int32
}

struct BatchResponseStream {
    private enum Stage: Hashable {
        case banner
        case header(index: Int)
        case body(index: Int, remaining: Int, exitCode: Int32)
        case complete
    }

    private enum Header {
        case incomplete
        case malformed
        case parsed(BatchRecord, size: Int)
    }

    private let delimiter: Data
    private let labels: [String]
    private let limits: BatchLimits

    private var stage = Stage.banner
    private var pending = Data()
    private var cursor = 0
    private var consumed = 0
    private var received = 0
    private var body = Data()
    private var frames: [BatchFrame] = []

    init(nonce: BatchNonce, labels: [String], limits: BatchLimits) {
        self.delimiter = nonce.delimiter
        self.labels = labels
        self.limits = limits
    }

    mutating func append(_ chunk: Data) throws {
        received += chunk.count
        guard received <= limits.maximumResponseBytes else { throw oversized() }
        pending.append(chunk)
        while try advance() {}
        if cursor > 0 {
            pending.removeSubrange(pending.startIndex..<(pending.startIndex + cursor))
            cursor = 0
        }
    }

    func finish() throws -> [BatchFrame] {
        switch stage {
        case .complete:
            return frames
        case .banner:
            throw BatchFramingError.missingSection(label: label(0))
        case .body(let index, _, _):
            throw BatchFramingError.unterminatedSection(label: label(index))
        case .header(let index):
            throw index < labels.count
                ? BatchFramingError.missingSection(label: label(index))
                : BatchFramingError.unterminatedSection(label: label(index))
        }
    }

    private mutating func advance() throws -> Bool {
        switch stage {
        case .banner:
            return try openResponse()
        case .header(let index):
            return try readRecord(expecting: index)
        case .body(let index, let remaining, let exitCode):
            return fill(index, remaining, exitCode)
        case .complete:
            guard available == 0 else { throw BatchFramingError.trailingBytes(label: label(0)) }
            return false
        }
    }

    private mutating func openResponse() throws -> Bool {
        let start = pending.startIndex + cursor
        guard let match = pending.range(of: delimiter, in: start..<pending.endIndex) else {
            take(max(0, available - (delimiter.count - 1)))
            return false
        }
        take(match.lowerBound - start)
        switch header() {
        case .incomplete: return false
        case .malformed:
            take(1)
            return true
        case .parsed(let record, let size): return try enter(record, size: size, index: 0)
        }
    }

    private mutating func readRecord(expecting index: Int) throws -> Bool {
        switch header() {
        case .incomplete: return false
        case .malformed: throw BatchFramingError.desynchronised(label: label(index))
        case .parsed(let record, let size): return try enter(record, size: size, index: index)
        }
    }

    private mutating func enter(_ record: BatchRecord, size: Int, index: Int) throws -> Bool {
        switch record {
        case .section(let section, let length, let exitCode)
        where section == index && index < labels.count:
            guard consumed + size + length <= limits.maximumResponseBytes else { throw oversized() }
            take(size)
            body = Data()
            stage = .body(index: index, remaining: length, exitCode: exitCode)
        case .end(let count) where count == labels.count && index == labels.count:
            take(size)
            stage = .complete
        default:
            throw BatchFramingError.desynchronised(label: label(index))
        }
        return true
    }

    private mutating func fill(_ index: Int, _ remaining: Int, _ exitCode: Int32) -> Bool {
        let count = min(remaining, available)
        body.append(take(count))
        guard count == remaining else {
            stage = .body(index: index, remaining: remaining - count, exitCode: exitCode)
            return false
        }
        frames.append(BatchFrame(index: index, bytes: body, exitCode: exitCode))
        body = Data()
        stage = .header(index: index + 1)
        return true
    }

    private func header() -> Header {
        let start = pending.startIndex + cursor
        guard available >= delimiter.count else {
            return pending[start...].elementsEqual(delimiter.prefix(available)) ? .incomplete : .malformed
        }
        guard pending[start..<(start + delimiter.count)].elementsEqual(delimiter) else {
            return .malformed
        }
        let text = start + delimiter.count
        let limit = min(text + BatchRecord.headerLimit, pending.endIndex)
        guard let end = pending[text..<limit].firstIndex(of: 0x0A) else {
            return limit == pending.endIndex ? .incomplete : .malformed
        }
        guard let header = String(data: pending[text..<end], encoding: .utf8),
            let record = BatchRecord(header: header)
        else { return .malformed }
        return .parsed(record, size: end + 1 - start)
    }

    private var available: Int { pending.endIndex - (pending.startIndex + cursor) }

    @discardableResult
    private mutating func take(_ count: Int) -> Data {
        let start = pending.startIndex + cursor
        cursor += count
        consumed += count
        return Data(pending[start..<(start + count)])
    }

    private func oversized() -> BatchFramingError {
        .responseTooLarge(label: label(frames.count), limit: limits.maximumResponseBytes)
    }

    private func label(_ index: Int) -> String {
        index < labels.count ? labels[index] : labels.last ?? ""
    }
}
