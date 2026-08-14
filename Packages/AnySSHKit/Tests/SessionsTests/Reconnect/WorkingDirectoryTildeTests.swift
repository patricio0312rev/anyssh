import AnySSHCore
import Testing

@testable import Sessions

@Suite struct WorkingDirectoryTildeTests {
    private func payload(_ path: String) -> String? {
        WorkingDirectoryRestorer()
            .payload(for: WorkspaceLocation(path: path, provenance: .process))
            .map { String(decoding: $0, as: UTF8.self) }
    }

    @Test func aTildePathIsHandedToTheShellAsHome() {
        #expect(payload("~/src/web") == "cd \"$HOME\"/'src/web'\n")
    }

    @Test func theRestOfTheTildePathStaysQuoted() {
        #expect(payload("~/it's here") == "cd \"$HOME\"/'it'\\''s here'\n")
    }

    @Test func anAbsolutePathIsQuotedWhole() {
        #expect(payload("/var/www/site") == "cd '/var/www/site'\n")
    }

    @Test func aBareTildeSendsNothing() {
        #expect(payload("~") == nil)
    }

    @Test func aTildeElsewhereIsJustACharacter() {
        #expect(payload("/tmp/~backup") == "cd '/tmp/~backup'\n")
    }
}
