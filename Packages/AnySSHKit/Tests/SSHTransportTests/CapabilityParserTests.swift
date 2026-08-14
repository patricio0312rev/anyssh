import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite struct CapabilityParserTests {
    private let parser = CapabilityParser()

    @Test func parsesEverythingPresentFixtureFieldByField() throws {
        let value = try parser.parse(CapabilityFixtureData.everythingPresent)
        #expect(value.shell == "/bin/zsh")
        #expect(value.platform == "Darwin arm64")
        #expect(value.locale == "en_US.UTF-8")
        #expect(value.home == "/Users/dev")
        #expect(value.searchPath == "/Users/dev/.local/bin:/opt/homebrew/bin:/usr/bin")
        expect(value.git, path: "/opt/homebrew/bin/git", version: "2.54.0")
        expect(value.tmux, path: "/opt/homebrew/bin/tmux", version: "3.6a")
        expect(value.herdr.tool, path: "/Users/dev/.local/bin/herdr", version: "0.8.0")
        #expect(value.herdr.protocolVersion == 19)
    }

    @Test func parsesGitOnlyFixtureFieldByField() throws {
        let value = try parser.parse(CapabilityFixtureData.gitOnly)
        #expect(value.shell == "/bin/bash")
        #expect(value.platform == "Linux x86_64")
        #expect(value.locale == "C.UTF-8")
        #expect(value.home == "/home/dev")
        #expect(value.searchPath == "/usr/local/bin:/usr/bin:/bin")
        expect(value.git, path: "/usr/bin/git", version: "2.43.0")
        expect(value.tmux, path: nil, version: nil)
        expect(value.herdr.tool, path: nil, version: nil)
        #expect(value.herdr.protocolVersion == nil)
    }

    @Test func parsesNothingPresentFixtureFieldByField() throws {
        let value = try parser.parse(CapabilityFixtureData.nothingPresent)
        #expect(value.shell == "/bin/sh")
        #expect(value.platform == "FreeBSD amd64")
        #expect(value.locale == "C")
        #expect(value.home == "/home/operator")
        #expect(value.searchPath == "/usr/bin:/bin")
        expect(value.git, path: nil, version: nil)
        expect(value.tmux, path: nil, version: nil)
        expect(value.herdr.tool, path: nil, version: nil)
        #expect(value.herdr.protocolVersion == nil)
    }

    @Test func parsesOldGitFixtureAndRetainsItsDegradationInput() throws {
        let value = try parser.parse(CapabilityFixtureData.oldGit)
        #expect(value.shell == "/bin/zsh")
        #expect(value.platform == "Darwin arm64")
        #expect(value.locale == "en_US.UTF-8")
        #expect(value.home == "/Users/legacy")
        #expect(value.searchPath == "/usr/bin:/bin:/usr/sbin:/sbin")
        expect(value.git, path: "/usr/bin/git", version: "2.30.1")
        #expect(value.supportsGit(minimumVersion: "2.31.0") == false)
        #expect(value.supportsGit(minimumVersion: "2.30.0"))
    }

    private func expect(_ tool: ToolReport, path: String?, version: String?) {
        #expect(tool.path == path)
        #expect(tool.version == version)
        #expect(tool.isAvailable == (path != nil))
    }
}
