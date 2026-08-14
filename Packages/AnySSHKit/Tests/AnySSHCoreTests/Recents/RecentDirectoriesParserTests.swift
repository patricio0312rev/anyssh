import AnySSHCore
import Foundation
import Testing

@testable import AnySSHCore

@Suite
struct RecentDirectoriesParserTests {
    @Test func claudeHistoryParsesProjectAndTimestampAndDropsDisplay() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("claude-history.jsonl")
        let sightings = ClaudeHistoryParser().parse(bytes)
        #expect(sightings.count == 3)
        #expect(sightings[0].path == "/Users/dev/src/anyssh")
        #expect(sightings[0].source == .claude)
        #expect(sightings[0].lastUsed.timeIntervalSince1970 == 1_786_544_322.823)
        #expect(sightings[2].path.hasSuffix("fix-login-flow"))
        let display = "fix the login shell PATH leak"
        for sighting in sightings {
            #expect(!sighting.path.contains(display))
            #expect(String(describing: sighting.source) != display)
        }
    }

    @Test func claudeProjectsFallbackReadsCwdOffLineOne() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("claude-projects-fallback.jsonl")
        let stamped = Data("1786540000000\t".utf8) + bytes
        let sightings = ClaudeHistoryParser().parse(stamped)
        #expect(sightings.contains { $0.path == "/Users/dev/src/anyssh" })
        #expect(!sightings.isEmpty)
    }

    @Test func codexRolloutReadsPayloadCwdOnLineOne() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("codex-rollout-good.jsonl")
        let sightings = CodexRolloutParser().parse(bytes)
        #expect(sightings.count == 1)
        #expect(sightings[0].path == "/Users/dev/src/anyssh")
        #expect(sightings[0].source == .codex)
    }

    @Test func codexMalformedFirstLineIsSkipped() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("codex-rollout-malformed.jsonl")
        let sightings = CodexRolloutParser().parse(bytes)
        #expect(sightings.count == 1)
        #expect(sightings[0].path == "/Users/dev/src/agentkit")
    }

    @Test func cursorResolvesHyphenatedDirectoryAndFiltersNoise() throws {
        let existing: Set<String> = [
            "/Users",
            "/Users/dev",
            "/Users/dev/src",
            "/Users/dev/src/terminal-android",
            "/Users/dev/src/agentkit",
            "/Users/dev/src/anyssh",
        ]
        let bytes = try RecentDirectoriesFixtureData.bytes("cursor-listing.tsv")
        let sightings = CursorProjectResolver.parseListing(bytes) { existing.contains($0) }
        #expect(
            sightings.map(\.path) == [
                "/Users/dev/src/terminal-android",
                "/Users/dev/src/agentkit",
                "/Users/dev/src/anyssh",
            ]
        )
        #expect(sightings.allSatisfy { $0.source == .cursor })
    }

    @Test func openCodeDbRowsAndJsonFallbackParse() throws {
        let db = try RecentDirectoriesFixtureData.bytes("opencode-db.tsv")
        let fromDB = OpenCodeProjectParser().parse(db)
        #expect(fromDB.count == 4)
        #expect(fromDB[0].path == "/Users/dev/src/portfolio")
        #expect(fromDB[3].path == "/Users/dev/src/anyssh")
        #expect(fromDB[3].lastUsed.timeIntervalSince1970 == 1_786_545_915.143)

        let json = try RecentDirectoriesFixtureData.bytes("opencode-project.json")
        let fromJSON = OpenCodeProjectParser().parse(json)
        #expect(fromJSON.count == 1)
        #expect(fromJSON[0].path == "/Users/dev/src/acme-voice-agent")
        #expect(fromJSON[0].lastUsed.timeIntervalSince1970 == 1_769_438_268.121)
    }

    @Test func hostScanWireFormatMergesAndRanks() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("host-scan-merged.txt")
        let list = try RecentDirectoriesParser().parse(bytes, limit: 40)
        #expect(list.first?.path == "/Users/dev/src/anyssh")
        #expect(list.first?.sources == [.opencode, .claude, .codex])
        #expect(list.map(\.path).contains("/Users/dev/src/terminal-android"))
        #expect(
            list.contains {
                $0.path
                    == "/Users/dev/src/client-project/.claude-worktrees/fix-login-flow"
            }
        )
    }

    @Test func promptTextNeverLeavesTheClaudeReader() throws {
        let bytes = try RecentDirectoriesFixtureData.bytes("claude-history.jsonl")
        let text = try RecentDirectoriesFixtureData.text("claude-history.jsonl")
        let display = "fix the login shell PATH leak"
        #expect(text.contains(display))
        let sightings = ClaudeHistoryParser().parse(bytes)
        let joined = sightings.map { "\($0.path)|\($0.source.rawValue)|\($0.lastUsed.timeIntervalSince1970)" }
            .joined(separator: "\n")
        #expect(!joined.contains(display))
        #expect(!joined.contains("🔧"))
        #expect(!joined.contains("pastedContents"))
        #expect(!joined.contains("sessionId"))
    }
}
