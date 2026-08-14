import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@Suite struct TerminalResizeGuardTests {
    @Test func theSoftResettingResizeAppearsNowhereInTheTree() throws {
        let needle = "." + "resize(cols:"
        let offenders = try Self.swiftFiles().filter { file in
            try String(contentsOf: file, encoding: .utf8).contains(needle)
        }

        #expect(offenders.map(\.path) == [])
    }

    @Test func aResizeKeepsTheModesARunningProgramSet() {
        let engine = TerminalFixture.engine(renderer: .coreText)
        engine.feed(Array("\u{1b}[?1049h\u{1b}[?1h\u{1b}[?1000h".utf8)[...])
        let before = engine.modes

        engine.resize(to: TerminalSize(columns: 100, rows: 30))

        let expected = TerminalModeSnapshot(
            applicationCursor: true,
            alternateBuffer: true,
            mouseReporting: true
        )
        #expect(before == expected)
        #expect(engine.modes == before)
        #expect(engine.size.columns == 100)
        #expect(engine.size.rows == 30)
    }

    @Test func aResizeToTheSameCellCountIsNotAResize() {
        let engine = TerminalFixture.engine(renderer: .coreText)
        let surface = engine.surface.frame

        engine.resize(to: .standard)

        #expect(engine.surface.frame == surface)
    }

    private static func swiftFiles() -> [URL] {
        let root = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let trees = ["AnySSH", "AnySSHUITests", "Packages/AnySSHKit/Sources", "Packages/AnySSHKit/Tests"]
        return trees.flatMap { tree -> [URL] in
            let directory = root.appending(path: tree)
            let files = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil)
            let contents = files?.compactMap { $0 as? URL } ?? []
            return contents.filter { $0.pathExtension == "swift" }
        }
    }
}
