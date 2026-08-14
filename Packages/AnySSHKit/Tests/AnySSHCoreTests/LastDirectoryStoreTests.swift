import Foundation
import Testing

@testable import AnySSHCore

@Suite struct LastDirectoryStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: "LastDirectoryStoreTests-\(UUID().uuidString)")
    private let remote = RemoteID(rawValue: "build-box")

    @Test func remembersAcrossAFreshStoreOverTheSameDirectory() {
        defer { try? FileManager.default.removeItem(at: directory) }
        LastDirectoryStore(directory: directory).remember("/home/ci/work", for: remote)

        #expect(LastDirectoryStore(directory: directory).path(for: remote) == "/home/ci/work")
    }

    @Test func aHostNeverVisitedRemembersNothing() {
        defer { try? FileManager.default.removeItem(at: directory) }

        #expect(LastDirectoryStore(directory: directory).path(for: remote) == nil)
    }

    @Test func aBlankPathForgetsRatherThanStoringNothing() {
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LastDirectoryStore(directory: directory)
        store.remember("/home/ci/work", for: remote)

        store.remember("  ", for: remote)

        #expect(store.path(for: remote) == nil)
    }

    @Test func hostsDoNotShareADirectory() {
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LastDirectoryStore(directory: directory)
        store.remember("/home/ci/work", for: remote)
        store.remember("/var/log", for: RemoteID(rawValue: "edge"))

        #expect(store.path(for: remote) == "/home/ci/work")
        #expect(store.path(for: RemoteID(rawValue: "edge")) == "/var/log")
    }
}
