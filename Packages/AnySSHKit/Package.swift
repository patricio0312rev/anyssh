// swift-tools-version: 6.3

import PackageDescription

let baseSettings: [SwiftSetting] = [
    .swiftLanguageMode(.v6),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]

let mainActorSettings: [SwiftSetting] = baseSettings + [.defaultIsolation(MainActor.self)]

let moduleNames = [
    "AnySSHCore",
    "SSHTransport",
    "TerminalEmulator",
    "Highlighting",
    "Sessions",
    "Multiplexers",
    "GitClient",
    "FileTransfer",
    "AnySSHMocks",
    "AnySSHUI",
]

let grammars = [
    ("tree-sitter-swift", "TreeSitterSwift"),
    ("tree-sitter-typescript", "TreeSitterTypeScript"),
    ("tree-sitter-javascript", "TreeSitterJavaScript"),
    ("tree-sitter-python", "TreeSitterPython"),
    ("tree-sitter-go", "TreeSitterGo"),
    ("tree-sitter-json", "TreeSitterJSON"),
    ("tree-sitter-yaml", "TreeSitterYAML"),
    ("tree-sitter-markdown", "TreeSitterMarkdown"),
]

let grammarProducts: [Target.Dependency] = grammars.map {
    .product(name: $0.1, package: $0.0)
}

let treeSitter: Target.Dependency = .product(name: "SwiftTreeSitter", package: "swift-tree-sitter")
let asyncAlgorithms: Target.Dependency = .product(
    name: "AsyncAlgorithms",
    package: "swift-async-algorithms"
)

func library(_ name: String) -> Product {
    .library(name: name, targets: [name])
}

func module(_ name: String, _ dependencies: [Target.Dependency], settings: [SwiftSetting] = baseSettings)
    -> Target
{
    .target(name: name, dependencies: dependencies, swiftSettings: settings)
}

func suite(
    _ moduleName: String,
    extraDependencies: [Target.Dependency] = [],
    settings: [SwiftSetting] = baseSettings
) -> Target {
    .testTarget(
        name: "\(moduleName)Tests",
        dependencies: [.target(name: moduleName), "Fixtures"] + extraDependencies,
        swiftSettings: settings
    )
}

let package = Package(
    name: "AnySSHKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: moduleNames.map(library),
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm", exact: "1.18.0"),
        .package(url: "https://github.com/tree-sitter/swift-tree-sitter", exact: "0.10.0"),
        .package(
            url: "https://github.com/alex-pinkus/tree-sitter-swift",
            exact: "0.7.3-with-generated-files"
        ),
        .package(url: "https://github.com/tree-sitter/tree-sitter-typescript", exact: "0.23.2"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-javascript", exact: "0.23.1"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-python", exact: "0.23.6"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-go", exact: "0.25.0"),
        .package(url: "https://github.com/tree-sitter/tree-sitter-json", exact: "0.24.8"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-yaml", exact: "0.7.0"),
        .package(url: "https://github.com/tree-sitter-grammars/tree-sitter-markdown", exact: "0.5.3"),
        .package(url: "https://github.com/swhitty/SwiftDraw", exact: "0.29.0"),
        .package(url: "https://github.com/LiYanan2004/MarkdownView", exact: "3.0.0", traits: []),
        .package(url: "https://github.com/swiftlang/swift-markdown", exact: "0.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.4"),
        .package(url: "https://github.com/apple/swift-async-algorithms", exact: "1.1.5"),
    ],
    targets: [
        .binaryTarget(name: "CSSH", path: "Vendor/CSSH.xcframework"),
        .target(name: "Fixtures", resources: [.copy("Data")], swiftSettings: baseSettings),
        module("AnySSHCore", []),
        module("SSHTransport", ["AnySSHCore", "CSSH"]),
        module("TerminalEmulator", ["AnySSHCore", asyncAlgorithms]),
        module("Highlighting", ["AnySSHCore", treeSitter] + grammarProducts),
        module("Sessions", ["AnySSHCore", "SSHTransport", "TerminalEmulator", asyncAlgorithms]),
        module("GitClient", ["AnySSHCore", "SSHTransport"]),
        module("FileTransfer", ["AnySSHCore", "SSHTransport"]),
        module("Multiplexers", ["AnySSHCore", "TerminalEmulator", "Sessions"]),
        module("AnySSHMocks", ["AnySSHCore"]),
        module(
            "AnySSHUI",
            [
                "AnySSHCore", "SSHTransport", "TerminalEmulator", "Highlighting", "Sessions",
                "Multiplexers", "GitClient", "FileTransfer",
                .product(name: "SwiftTerm", package: "SwiftTerm"),
                .product(name: "SwiftDraw", package: "SwiftDraw"),
                .product(name: "MarkdownView", package: "MarkdownView"),
                .product(name: "Markdown", package: "swift-markdown"),
            ],
            settings: mainActorSettings
        ),
        suite("AnySSHCore"),
        suite("SSHTransport", extraDependencies: ["CSSH"]),
        suite("TerminalEmulator", extraDependencies: ["AnySSHMocks"]),
        suite("Highlighting"),
        suite("Sessions"),
        suite("Multiplexers", extraDependencies: ["AnySSHMocks"]),
        suite("GitClient"),
        suite("FileTransfer"),
        suite("AnySSHMocks"),
        .testTarget(
            name: "AnySSHUISnapshotTests",
            dependencies: [
                "AnySSHUI", "AnySSHMocks", "Fixtures",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            swiftSettings: mainActorSettings
        ),
    ]
)
