import AnySSHCore
import Foundation

public enum FileFixtures {
    public static let root = GitFixtures.root
    public static let repository = GitFixtures.repository

    public static let swiftSource = """
        import AnySSHCore
        import SwiftUI

        struct FileBrowserScreen: View {
            let model: FileBrowserModel
            let highlighter: any SyntaxHighlighter

            var body: some View {
                List(model.entries) { entry in
                    FileEntryRow(entry: entry, onOpen: { model.open(entry) })
                }
                .task { await model.load() }
            }

            private func open(_ entry: DirectoryEntry) async throws -> FileContentCommand.Content {
                try await model.browser.read(path: model.fullPath(of: entry))
            }
        }

        extension FileBrowserScreen {
            static let entryLimit = 2_000
            static let placeholder = "a line long enough to run past the trailing edge of any phone"
        }
        """

    public static let jsonSource = """
        {
          "name": "anyssh",
          "version": "1.4.0",
          "private": true,
          "platforms": ["ios", "ipados"],
          "dependencies": {
            "SwiftTerm": "1.18.0",
            "SwiftDraw": "0.29.0",
            "swift-tree-sitter": "0.10.0"
          },
          "grammars": [
            { "language": "swift", "queries": 3, "enabled": true },
            { "language": "json", "queries": 1, "enabled": true },
            { "language": "yaml", "queries": 1, "enabled": false }
          ],
          "limits": { "blobBytes": 2097152, "entries": 2000, "svgBytes": 262144 }
        }
        """

    public static let markdownSource = """
        # AnySSH

        A real terminal, remote git and remote files over SSH. No backend, no account,
        nothing installed on the host.

        ## Getting started

        1. Add a host with its address and user.
        2. Import a private key, or let the app prompt for a password.
        3. Open the workspace and start working.

        > Keys and passphrases live in the iOS Keychain, on device.

        ```swift
        let session = try await transport.connect(to: remote)
        try await session.requestPTY(columns: 80, rows: 24)
        ```

        | Surface | Font |
        | --- | --- |
        | Chrome | SF with Dynamic Type |
        | Code | JetBrains Mono |
        """

    public static let svgSource = """
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">
          <rect width="120" height="120" rx="24" fill="#2d2a2e"/>
          <circle cx="60" cy="48" r="22" fill="#ab9df2"/>
          <path d="M24 96 L60 66 L96 96 Z" fill="#78dce8"/>
          <path d="M32 24 L44 36 L32 48" stroke="#a9dc76" stroke-width="6" fill="none"/>
        </svg>
        """

    public static let listings: [String: DirectoryListing] = [
        root: DirectoryListing(
            path: root,
            entries: [
                DirectoryEntry(name: "Packages", kind: .directory),
                DirectoryEntry(name: "Scripts", kind: .directory),
                DirectoryEntry(name: "Config", kind: .directory),
                DirectoryEntry(name: "docs", kind: .directory),
                DirectoryEntry(name: "AGENTS.md", kind: .file),
                DirectoryEntry(name: "Makefile", kind: .file),
                DirectoryEntry(name: "Package.swift", kind: .file),
                DirectoryEntry(name: "README.md", kind: .file),
                DirectoryEntry(name: "config.json", kind: .file),
                DirectoryEntry(name: "icon.svg", kind: .file),
                DirectoryEntry(name: "screenshot.png", kind: .file),
                DirectoryEntry(name: "latest", kind: .symlink),
            ]
        ),
        root + "/Packages": DirectoryListing(
            path: root + "/Packages",
            entries: [
                DirectoryEntry(name: "AnySSHKit", kind: .directory),
                DirectoryEntry(name: "Package.resolved", kind: .file),
                DirectoryEntry(name: "Package.swift", kind: .file),
            ]
        ),
        root + "/docs": DirectoryListing(path: root + "/docs", entries: []),
    ]

    public static let contents: [String: String] = [
        root + "/Package.swift": swiftSource,
        root + "/config.json": jsonSource,
        root + "/README.md": markdownSource,
        root + "/AGENTS.md": markdownSource,
        root + "/icon.svg": svgSource,
    ]

    public static func blob(_ path: String) -> BlobRef {
        BlobRef(repository: repository, objectID: objectID(for: path), path: path)
    }

    private static func objectID(for path: String) -> String {
        String(format: "%08x", abs(path.hashValue)) + "00000000000000000000000000000000"
    }
}
