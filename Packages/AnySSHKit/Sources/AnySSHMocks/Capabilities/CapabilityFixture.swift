import AnySSHCore
import Foundation

public enum CapabilityFixture: String, CaseIterable, Sendable {
    case everythingPresent = "everything-present"
    case gitOnly = "git-only"
    case nothingPresent = "nothing-present"
    case oldGit = "old-git"

    public static var deepLinks: [URL] { allCases.map(\.deepLink) }

    public var deepLink: URL {
        var components = URLComponents()
        components.scheme = "anyssh"
        components.host = "capabilities"
        components.path = "/\(rawValue)"
        return components.url ?? URL(filePath: rawValue)
    }

    public var capabilities: HostCapabilities {
        switch self {
        case .everythingPresent:
            return HostCapabilities(
                shell: "/bin/zsh",
                platform: "Darwin arm64",
                locale: "en_US.UTF-8",
                home: "/home/dev",
                searchPath: "/home/dev/.local/bin:/usr/local/bin:/usr/bin",
                git: ToolReport(path: "/opt/homebrew/bin/git", version: "2.54.0"),
                tmux: ToolReport(path: "/opt/homebrew/bin/tmux", version: "3.6a"),
                herdr: HerdrReport(
                    tool: ToolReport(path: "/home/dev/.local/bin/herdr", version: "0.8.0"),
                    protocolVersion: 19
                )
            )
        case .gitOnly:
            return HostCapabilities(
                shell: "/bin/bash",
                platform: "Linux x86_64",
                locale: "C.UTF-8",
                home: "/home/dev",
                searchPath: "/usr/local/bin:/usr/bin:/bin",
                git: ToolReport(path: "/usr/bin/git", version: "2.43.0"),
                tmux: ToolReport(path: nil, version: nil),
                herdr: HerdrReport(tool: ToolReport(path: nil, version: nil), protocolVersion: nil)
            )
        case .nothingPresent:
            return HostCapabilities(
                shell: "/bin/sh",
                platform: "FreeBSD amd64",
                locale: "C",
                home: "/home/operator",
                searchPath: "/usr/bin:/bin",
                git: ToolReport(path: nil, version: nil),
                tmux: ToolReport(path: nil, version: nil),
                herdr: HerdrReport(tool: ToolReport(path: nil, version: nil), protocolVersion: nil)
            )
        case .oldGit:
            return HostCapabilities(
                shell: "/bin/zsh",
                platform: "Darwin arm64",
                locale: "en_US.UTF-8",
                home: "/Users/legacy",
                searchPath: "/usr/bin:/bin:/usr/sbin:/sbin",
                git: ToolReport(path: "/usr/bin/git", version: "2.30.1"),
                tmux: ToolReport(path: nil, version: nil),
                herdr: HerdrReport(tool: ToolReport(path: nil, version: nil), protocolVersion: nil)
            )
        }
    }
}

public struct FixtureCapabilityProbe: CapabilityProbe {
    private let value: HostCapabilities

    public init(fixture: CapabilityFixture) {
        value = fixture.capabilities
    }

    public init?(deepLink: URL) {
        guard deepLink.scheme == "anyssh", deepLink.host == "capabilities",
            let fixture = CapabilityFixture(rawValue: deepLink.pathComponents.last ?? "")
        else { return nil }
        value = fixture.capabilities
    }

    public func probe() async throws -> HostCapabilities {
        value
    }
}
