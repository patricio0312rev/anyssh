import AnySSHCore
import Foundation
import TerminalEmulator
import Testing

@testable import AnySSHUI

@MainActor
@Suite struct GestureSettingsModelTests {
    @Test func aFreshDirectoryOpensOnTheShippedDefaults() throws {
        let model = GestureSettingsModel(directory: try Self.directory())

        #expect(model.binding(for: .swipeLeft)?.value == "session.next")
        #expect(model.binding(for: .swipeRight)?.value == "session.previous")
        #expect(model.saveFailure == nil)
    }

    @Test func aBoundSlotSurvivesReopeningTheScreen() throws {
        let directory = try Self.directory()
        let model = GestureSettingsModel(directory: directory)

        model.bind(GestureLayout.Binding(kind: .chord, value: "escape"), to: .swipeRight)

        let reopened = GestureSettingsModel(directory: directory)
        #expect(reopened.binding(for: .swipeRight)?.kind == .chord)
        #expect(reopened.binding(for: .swipeRight)?.value == "escape")
    }

    @Test func unbindingRemovesTheSlotFromWhatIsPersisted() throws {
        let directory = try Self.directory()
        let model = GestureSettingsModel(directory: directory)

        model.bind(nil, to: .swipeLeft)

        #expect(GestureLayout.load(from: directory).binding(for: "swipeLeft") == nil)
    }

    @Test func resetRestoresEverySlotTheBuildShipsWith() throws {
        let directory = try Self.directory()
        let model = GestureSettingsModel(directory: directory)
        model.bind(nil, to: .swipeLeft)
        model.bind(GestureLayout.Binding(kind: .chord, value: "escape"), to: .swipeRight)

        model.reset()

        #expect(model.layout == GestureLayout.defaults)
        #expect(GestureLayout.load(from: directory) == GestureLayout.defaults)
    }

    @Test func aDirectoryThatCannotBeWrittenIsReported() throws {
        let file = try Self.directory().appending(path: "occupied")
        try Data().write(to: file)
        let model = GestureSettingsModel(directory: file)

        model.bind(nil, to: .swipeLeft)

        #expect(model.saveFailure != nil)
    }

    private static func directory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "gesture-settings-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
