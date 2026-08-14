import Foundation
import Testing

@testable import AnySSHCore

@Suite struct RemoteStoreTests {
    @Test func fiveRemotesSurviveANewStoreOverTheSameDirectory() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let written = (0..<5).map(RemoteStoreFixture.numbered)
        let store = FileRemoteStore(directory: directory.url)
        for remote in written {
            try await store.save(remote)
        }

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        #expect(reopened == written)
        #expect(reopened.map(\.name) == ["Host 0", "Host 1", "Host 2", "Host 3", "Host 4"])
        #expect(reopened.map(\.orderIndex) == [0, 1, 2, 3, 4])
    }

    @Test func everyOptionalFieldRoundTripsByteForByte() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        try await store.save(RemoteStoreFixture.awkward)

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        let recovered = try #require(reopened.first)
        #expect(recovered == RemoteStoreFixture.awkward)
        #expect(recovered.startPath == RemoteStoreFixture.awkward.startPath)
        #expect(recovered.startupCommand == RemoteStoreFixture.awkward.startupCommand)
        #expect(recovered.tag == RemoteStoreFixture.awkward.tag)
        #expect(Array(recovered.name.utf8) == Array(RemoteStoreFixture.awkward.name.utf8))
    }

    @Test func reorderingIsPersisted() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for remote in (0..<5).map(RemoteStoreFixture.numbered) {
            try await store.save(remote)
        }
        try await store.move(fromOffsets: IndexSet(integer: 4), toOffset: 0)

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        #expect(reopened.map(\.name) == ["Host 4", "Host 0", "Host 1", "Host 2", "Host 3"])
        #expect(reopened.map(\.orderIndex) == [0, 1, 2, 3, 4])
    }

    @Test func explicitOrderingIsPersisted() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for remote in (0..<3).map(RemoteStoreFixture.numbered) {
            try await store.save(remote)
        }
        try await store.reorder(to: [2, 0, 1].map { RemoteID(rawValue: "host-\($0)") })

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        #expect(reopened.map(\.name) == ["Host 2", "Host 0", "Host 1"])
    }

    @Test func aRepeatedOrEmptyOrderIsSurvivable() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for remote in (0..<3).map(RemoteStoreFixture.numbered) {
            try await store.save(remote)
        }
        let second = RemoteID(rawValue: "host-2")
        try await store.reorder(to: [second, second, RemoteID(rawValue: "absent")])

        #expect(try await store.remotes().map(\.name) == ["Host 2", "Host 0", "Host 1"])
    }

    @Test func deletionIsPersisted() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for remote in (0..<3).map(RemoteStoreFixture.numbered) {
            try await store.save(remote)
        }
        try await store.delete(RemoteID(rawValue: "host-1"))

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        #expect(reopened.map(\.name) == ["Host 0", "Host 2"])
        #expect(reopened.map(\.orderIndex) == [0, 1])
    }

    @Test func anAbsentFileReadsAsNoRemotes() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        #expect(try await FileRemoteStore(directory: directory.url).remotes().isEmpty)
    }

    @Test func everyAuthMethodSurvivesTheRoundTrip() async throws {
        let directory = TemporaryDirectory()
        defer { directory.remove() }

        let store = FileRemoteStore(directory: directory.url)
        for method in AuthMethod.allCases {
            try await store.save(RemoteStoreFixture.authenticated(by: method))
        }

        let reopened = try await FileRemoteStore(directory: directory.url).remotes()
        #expect(reopened.map(\.authMethod) == AuthMethod.allCases)
    }
}
