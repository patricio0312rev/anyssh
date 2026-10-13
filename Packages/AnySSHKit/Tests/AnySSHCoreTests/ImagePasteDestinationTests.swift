import Foundation
import Testing

@testable import AnySSHCore

@Suite struct ImagePasteDestinationTests {
    @Test func namesFilesByUTCTimestampWithMilliseconds() {
        let date = Date(timeIntervalSince1970: 1_760_364_153.5)

        #expect(
            ImagePasteDestination.fileName(at: date, token: "a1b2c3d4", format: .png)
                == "paste-20251013-140233-500-a1b2c3d4.png"
        )
        #expect(
            ImagePasteDestination.fileName(at: date, token: "a1b2c3d4", format: .jpeg)
                == "paste-20251013-140233-500-a1b2c3d4.jpg"
        )
    }

    @Test func namesSortInTimeOrder() {
        let earlier = ImagePasteDestination.fileName(
            at: Date(timeIntervalSince1970: 1_760_364_153), token: "ffffffff", format: .png)
        let later = ImagePasteDestination.fileName(
            at: Date(timeIntervalSince1970: 1_760_364_154), token: "00000000", format: .png)

        #expect(earlier < later)
    }

    @Test func theSameMillisecondStillGivesTwoNames() {
        let date = Date(timeIntervalSince1970: 1_760_364_153.5)

        #expect(
            ImagePasteDestination.fileName(at: date, token: "a1b2c3d4", format: .png)
                != ImagePasteDestination.fileName(at: date, token: "e5f6a7b8", format: .png)
        )
    }

    #if os(macOS)
    @Test func preparesAPrivateDirectoryUnderTheCacheHome() throws {
        let home = try scratchHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let outcome = try CommandsSubprocess.sh(
            ImagePasteDestination.prepareScript,
            overrides: ["HOME": path(of: home)],
            removing: ["XDG_CACHE_HOME"]
        )
        let printed = String(decoding: outcome.stdout, as: UTF8.self)
        let expected = path(of: home.appending(path: ".cache/anyssh/paste"))

        #expect(outcome.exitCode == 0)
        #expect(printed == expected)
        let mode = try FileManager.default.attributesOfItem(atPath: expected)[.posixPermissions]
        #expect((mode as? NSNumber)?.intValue == 0o700)
    }

    @Test func honoursXDGCacheHome() throws {
        let home = try scratchHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let cache = path(of: home.appending(path: "xdg"))

        let outcome = try CommandsSubprocess.sh(
            ImagePasteDestination.prepareScript,
            overrides: ["HOME": path(of: home), "XDG_CACHE_HOME": cache]
        )

        #expect(String(decoding: outcome.stdout, as: UTF8.self) == cache + "/anyssh/paste")
    }

    @Test func sweepsPastesAtTheRetentionBoundaryAndNothingElse() throws {
        let home = try scratchHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let directory = home.appending(path: ".cache/anyssh/paste")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let day = 86_400.0
        let retention = Double(ImagePasteDestination.retentionDays) * day
        let expired = directory.appending(path: "paste-expired.png")
        let keptLastHour = directory.appending(path: "paste-kept.png")
        let foreign = directory.appending(path: "notes.txt")
        let ages = [
            (expired, retention + 3_600), (keptLastHour, retention - 3_600), (foreign, retention * 2),
        ]
        for (file, age) in ages {
            try Data("x".utf8).write(to: file)
            try FileManager.default.setAttributes(
                [.modificationDate: Date().addingTimeInterval(-age)],
                ofItemAtPath: file.path(percentEncoded: false))
        }

        let outcome = try CommandsSubprocess.sh(
            ImagePasteDestination.prepareScript,
            overrides: ["HOME": path(of: home)],
            removing: ["XDG_CACHE_HOME"]
        )

        #expect(outcome.exitCode == 0)
        #expect(!FileManager.default.fileExists(atPath: expired.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: keptLastHour.path(percentEncoded: false)))
        #expect(FileManager.default.fileExists(atPath: foreign.path(percentEncoded: false)))
    }

    @Test func survivesTheLoginShellWrapper() throws {
        let home = try scratchHome()
        defer { try? FileManager.default.removeItem(at: home) }

        let outcome = try CommandsSubprocess.sh(
            LoginShellWrapper.wrap(ImagePasteDestination.prepareScript),
            overrides: CommandsSubprocess.quietZshEnvironment.merging(
                ["HOME": path(of: home)]
            ) { _, override in override },
            removing: ["XDG_CACHE_HOME"]
        )

        #expect(String(decoding: outcome.stdout, as: UTF8.self).hasSuffix("/.cache/anyssh/paste"))
    }

    private func scratchHome() throws -> URL {
        let home = FileManager.default.temporaryDirectory
            .appending(path: "anyssh-paste-home-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: home, withIntermediateDirectories: true)
        return home.resolvingSymlinksInPath()
    }

    private func path(of url: URL) -> String {
        let path = url.path(percentEncoded: false)
        return path.hasSuffix("/") ? String(path.dropLast()) : path
    }
    #endif
}
