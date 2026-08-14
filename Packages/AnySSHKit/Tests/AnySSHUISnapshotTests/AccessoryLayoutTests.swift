import AnySSHCore
import Foundation
import Testing

@Suite struct AccessoryLayoutTests {
    @Test func roundTripsFortyKeysWithDuplicatesAndAChord() throws {
        let keys = (0..<40).map { index in
            AccessoryLayout.Key(
                id: "custom.\(index)",
                label: index.isMultiple(of: 2) ? "`" : "K\(index)",
                tap: index.isMultiple(of: 2) ? .key("`") : .key("k"),
                doubleTap: .none,
                longPress: index == 39 ? .chord("C-x C-s") : .none
            )
        }
        let layout = AccessoryLayout(keys: keys)
        let directory = try TemporaryDirectory()

        try layout.save(to: directory.url)

        #expect(AccessoryLayout.load(from: directory.url) == layout)
        #expect(AccessoryLayout.load(from: directory.url).keys.count == 40)
        #expect(AccessoryLayout.load(from: directory.url).keys.last?.longPress == .chord("C-x C-s"))
    }

    @Test func corruptLayoutFallsBackToDefaults() throws {
        let directory = try TemporaryDirectory()
        try Data("not json".utf8).write(to: AccessoryLayout.fileURL(in: directory.url))

        #expect(AccessoryLayout.load(from: directory.url) == .defaults)
        #expect(AccessoryLayout.load(from: directory.url).keys.isEmpty == false)
    }

    @Test func defaultKeysIncludeThePrefixKeyAndRepeatingArrows() {
        let ids = AccessoryLayout.defaults.keys.map(\.id)
        #expect(ids.contains("terminal.accessory.key.prefix"))
        #expect(ids.contains("terminal.accessory.key.pipe"))
        #expect(AccessoryLayout.defaults.keys.filter(\.repeats).count == 4)
    }

    @Test func aPersistedLayoutGainsThePrefixKeyInBackticksSlot() throws {
        let legacy = AccessoryLayout(keys: [
            AccessoryLayout.Key(id: "terminal.accessory.key.escape", label: "Esc", tap: .key("escape")),
            AccessoryLayout.Key(id: "terminal.accessory.key.backtick", label: "`", tap: .key("`")),
        ])

        let migrated = legacy.ensuringPrefixKey()

        #expect(migrated.keys.contains { $0.id == "terminal.accessory.key.prefix" })
        #expect(migrated.keys.contains { $0.id == "terminal.accessory.key.backtick" } == false)
        #expect(migrated.keys.count == 2)
    }

    @Test func aPersistedLayoutWithoutBacktickAppendsThePrefixKey() throws {
        let legacy = AccessoryLayout(keys: [
            AccessoryLayout.Key(id: "terminal.accessory.key.escape", label: "Esc", tap: .key("escape"))
        ])

        let migrated = legacy.ensuringPrefixKey()

        #expect(migrated.keys.count == 2)
        #expect(migrated.keys.last?.id == "terminal.accessory.key.prefix")
    }

    @Test func anAlreadyMigratedLayoutIsUntouched() throws {
        #expect(AccessoryLayout.defaults.ensuringPrefixKey() == .defaults)
    }

    @Test func movingAKeyPersistsBesideTheRemoteStore() throws {
        let directory = try TemporaryDirectory()
        let remoteStore = directory.url.appending(path: "remotes.json")
        let moved = AccessoryLayout.defaults.moved(
            id: "terminal.accessory.key.tab",
            before: "terminal.accessory.key.escape"
        )

        try moved.save(for: remoteStore)

        #expect(AccessoryLayout.load(for: remoteStore).keys.first?.id == "terminal.accessory.key.tab")
        #expect(FileManager.default.fileExists(atPath: AccessoryLayout.fileURL(in: directory.url).path))
    }
}

private final class TemporaryDirectory {
    let url: URL

    init() throws {
        url = FileManager.default.temporaryDirectory
            .appending(path: "anyssh-accessory-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}
