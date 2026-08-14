import Foundation
import Testing

@testable import AnySSHUI

@Suite struct FileIconMappingTests {
    @Test func resolvesFortySevenFileNames() {
        let cases: [(String, String)] = [
            ("Main.swift", "swift"),
            ("ViewController.m", "objective-c"),
            ("Bridge.mm", "objective-cpp"),
            ("util.c", "c"),
            ("engine.cpp", "cpp"),
            ("types.h", "h"),
            ("types.hpp", "hpp"),
            ("app.ts", "typescript"),
            ("index.d.ts", "typescript-def"),
            ("page.tsx", "react_ts"),
            ("widget.jsx", "react"),
            ("boot.js", "javascript"),
            ("config.json", "json"),
            ("ci.yaml", "yaml"),
            ("Cargo.toml", "toml"),
            ("notes.md", "markdown"),
            ("page.mdx", "mdx"),
            ("index.html", "html"),
            ("site.css", "css"),
            ("theme.scss", "sass"),
            ("setup.sh", "console"),
            ("train.py", "python"),
            ("main.go", "go"),
            ("go.mod", "go-mod"),
            ("lib.rs", "rust"),
            ("app.rb", "ruby"),
            ("Gemfile", "gemfile"),
            ("Dockerfile", "docker"),
            (".gitattributes", "git"),
            ("yarn.lock", "yarn"),
            ("photo.png", "image"),
            ("logo.svg", "svg"),
            ("clip.mp4", "video"),
            ("track.mp3", "audio"),
            ("bundle.zip", "zip"),
            ("Inter.ttf", "font"),
            ("manual.pdf", "pdf"),
            ("Info.plist", "xml"),
            ("schema.sql", "database"),
            ("package.json", "nodejs"),
            ("justfile", "just"),
            (".gitignore", "git"),
            ("readme.md", "readme"),
            ("docker-compose.yaml", "docker"),
            ("Package.swift", "swift"),
            ("mystery", "file"),
            ("data.unknownext", "file"),
        ]
        #expect(cases.count >= 40)
        for (input, expected) in cases {
            let resolved = FileIconResolver.icon(forFile: input).rawValue
            #expect(resolved == expected, "\(input) -> \(resolved), want \(expected)")
        }
    }

    @Test func resolvesFolderNames() {
        let cases: [(String, Bool, Bool, String)] = [
            ("src", false, false, "folder-src"),
            ("src", true, false, "folder-src-open"),
            ("docs", false, false, "folder-docs"),
            ("tests", false, false, "folder-test"),
            ("node_modules", false, false, "folder-node"),
            ("build", false, false, "folder-dist"),
            ("repo", false, true, "folder-root"),
            ("repo", true, true, "folder-root-open"),
            ("random", false, false, "folder"),
            ("random", true, false, "folder-open"),
        ]
        for (name, expanded, isRoot, expected) in cases {
            let resolved = FileIconResolver.icon(
                forFolder: name,
                expanded: expanded,
                isRoot: isRoot
            ).rawValue
            #expect(resolved == expected, "\(name) expanded=\(expanded) -> \(resolved)")
        }
    }

    @Test func exactFileNameBeatsExtension() {
        #expect(FileIconResolver.icon(forFile: "readme.md").rawValue == "readme")
        #expect(FileIconResolver.icon(forFile: "notes.md").rawValue == "markdown")
        #expect(FileIconResolver.icon(forFile: "justfile").rawValue == "just")
        #expect(FileIconResolver.icon(forFile: ".gitignore").rawValue == "git")
        #expect(FileIconResolver.icon(forFile: "docker-compose.yaml").rawValue == "docker")
        #expect(FileIconResolver.icon(forFile: "compose.yaml").rawValue == "docker")
    }

    @Test func multiPartExtensionBeatsShorterSuffix() {
        #expect(FileIconResolver.icon(forFile: "index.d.ts").rawValue == "typescript-def")
        #expect(FileIconResolver.icon(forFile: "types.d.mts").rawValue == "typescript-def")
        #expect(FileIconResolver.icon(forFile: "app.ts").rawValue == "typescript")
        #expect(FileIconResolver.icon(forFile: "config.yml.dist").rawValue == "yaml")
    }

    @Test func matchingIsCaseInsensitive() {
        #expect(FileIconResolver.icon(forFile: "Package.Swift").rawValue == "swift")
        #expect(FileIconResolver.icon(forFile: "README.MD").rawValue == "readme")
        #expect(FileIconResolver.icon(forFile: "DockerFile").rawValue == "docker")
        #expect(FileIconResolver.icon(forFile: "SRC").rawValue == "file")
        #expect(FileIconResolver.icon(forFolder: "SRC").rawValue == "folder-src")
        #expect(FileIconResolver.icon(forFolder: "Docs", expanded: true).rawValue == "folder-docs-open")
    }

    @Test func unknownFallsBackToDefaultFile() {
        #expect(FileIconResolver.icon(forFile: "mystery").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "data.unknownext").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: ".hidden").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "archive.zzzx").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "nope.foo.bar.baz").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "Makefile.bak.unknown").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "plain").rawValue == "file")
        #expect(FileIconResolver.icon(forFile: "x.zzzz").rawValue == "file")
    }

    @Test func pathUsesLastComponentOnly() {
        #expect(FileIconResolver.icon(forFile: "Sources/App/Main.swift").rawValue == "swift")
        #expect(FileIconResolver.icon(forFolder: "Packages/src").rawValue == "folder-src")
    }
}
