import Foundation
import Synchronization

@testable import AnySSHCore

final class FakeKeychain: KeychainBackend {
    struct Counts: Equatable, Sendable {
        var adds = 0
        var reads = 0
        var searches = 0
        var updates = 0
        var deletes = 0
    }

    private struct Entry {
        var item: KeychainItem
        var data: Data
    }

    private struct State {
        var entries: [String: Entry] = [:]
        var counts = Counts()
        var presentedReads = 0
        var enrolmentChanged = false
        var scripted: (operation: KeychainFailure.Operation, after: Int, status: OSStatus)?
        var seen: [KeychainFailure.Operation: Int] = [:]
    }

    private let state = Mutex(State())

    init(seeded entries: [(KeychainItem, Data)] = []) {
        for (item, data) in entries {
            state.withLock { $0.entries[Self.key(item)] = Entry(item: item, data: data) }
        }
    }

    var counts: Counts {
        state.withLock { $0.counts }
    }

    var presentedReads: Int {
        state.withLock { $0.presentedReads }
    }

    var stored: [KeychainItem] {
        state.withLock { $0.entries.values.map(\.item).sorted { $0.account < $1.account } }
    }

    func payload(service: String, account: String) -> Data? {
        state.withLock { $0.entries[Self.key(service: service, account: account)]?.data }
    }

    func fail(_ operation: KeychainFailure.Operation, after: Int, status: OSStatus = errSecIO) {
        state.withLock { $0.scripted = (operation, after, status) }
    }

    func clearFailures() {
        state.withLock { $0.scripted = nil }
    }

    func changeEnrolment() {
        state.withLock { $0.enrolmentChanged = true }
    }

    func add(_ item: KeychainItem, secret: Data) throws {
        try state.withLock {
            $0.counts.adds += 1
            try Self.scriptedFailure(&$0, .add)
            guard $0.entries[Self.key(item)] == nil else {
                throw KeychainFailure(.add, errSecDuplicateItem)
            }
            $0.entries[Self.key(item)] = Entry(item: item, data: secret)
        }
    }

    func data(for item: KeychainItem, presentation: (any BiometricPresentation)?) throws -> Data? {
        try state.withLock {
            $0.counts.reads += 1
            try Self.scriptedFailure(&$0, .read)
            guard item.gate == .none else {
                if $0.enrolmentChanged { throw KeychainFailure(.read, errSecAuthFailed) }
                guard presentation != nil else {
                    throw KeychainFailure(.read, errSecInteractionNotAllowed)
                }
                $0.presentedReads += 1
                return $0.entries[Self.key(item)]?.data
            }
            return $0.entries[Self.key(item)]?.data
        }
    }

    func items(inService service: String) throws -> [KeychainItem] {
        try state.withLock {
            $0.counts.searches += 1
            try Self.scriptedFailure(&$0, .search)
            return $0.entries.values.map(\.item)
                .filter { $0.service == service }
                .sorted { $0.account < $1.account }
        }
    }

    func restamp(_ item: KeychainItem, to updated: KeychainItem) throws {
        try state.withLock {
            $0.counts.updates += 1
            try Self.scriptedFailure(&$0, .update)
            guard let entry = $0.entries.removeValue(forKey: Self.key(item)) else {
                throw KeychainFailure(.update, errSecItemNotFound)
            }
            $0.entries[Self.key(updated)] = Entry(item: updated, data: entry.data)
        }
    }

    func delete(_ item: KeychainItem) throws {
        try state.withLock {
            $0.counts.deletes += 1
            try Self.scriptedFailure(&$0, .delete)
            $0.entries[Self.key(item)] = nil
        }
    }

    private static func scriptedFailure(_ state: inout State, _ operation: KeychainFailure.Operation)
        throws
    {
        let seen = (state.seen[operation] ?? 0) + 1
        state.seen[operation] = seen
        guard let scripted = state.scripted, scripted.operation == operation, seen > scripted.after
        else { return }
        throw KeychainFailure(operation, scripted.status)
    }

    private static func key(_ item: KeychainItem) -> String {
        key(service: item.service, account: item.account)
    }

    private static func key(service: String, account: String) -> String {
        "\(service)\u{1}\(account)"
    }
}
