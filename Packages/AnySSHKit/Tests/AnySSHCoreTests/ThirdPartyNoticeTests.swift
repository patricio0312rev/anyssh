import Foundation
import Testing

@testable import AnySSHCore

@Suite struct ThirdPartyNoticeTests {
    @Test func everyNoticeHasItsCollectedText() throws {
        let directory = repositoryRoot().appending(path: "AnySSH/Resources/Licences")

        for notice in ThirdPartyNotices.all {
            let file = directory.appending(path: "\(notice.resource).txt")
            let text = try? String(contentsOf: file, encoding: .utf8)
            #expect(
                (text?.count ?? 0) > 200,
                Comment(rawValue: "\(notice.name) has no collected licence at \(notice.resource).txt")
            )
        }
    }

    @Test func everyCollectedTextIsListed() throws {
        let directory = repositoryRoot().appending(path: "AnySSH/Resources/Licences")
        let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasSuffix(".txt") }
            .map { String($0.dropLast(4)) }
        let listed = Set(ThirdPartyNotices.all.map(\.resource))

        #expect(Set(files).subtracting(listed).isEmpty)
    }

    @Test func everyShippedPackageIsAttributed() throws {
        let manifest = try String(
            contentsOf: repositoryRoot().appending(path: "Packages/AnySSHKit/Package.swift"),
            encoding: .utf8
        )
        let listed = ThirdPartyNotices.all.map { $0.name.lowercased() }

        for package in Self.shippedPackages(in: manifest) {
            #expect(
                listed.contains(package.lowercased()),
                Comment(rawValue: "\(package) ships in the app and has no third-party notice")
            )
        }
    }

    private static func shippedPackages(in manifest: String) -> [String] {
        let testOnly: Set<String> = [
            "swift-snapshot-testing", "swift-custom-dump", "xctest-dynamic-overlay",
            "swift-argument-parser", "swift-syntax", "swift-collections", "swift-async-algorithms",
            "swift-cmark", "Highlightr", "RichText",
        ]
        var packages = [String]()
        for line in manifest.split(separator: "\n") where line.contains("url:") {
            guard let range = line.range(of: "github.com/") ?? line.range(of: "://") else { continue }
            let tail = line[range.upperBound...]
            guard let name = tail.split(separator: "\"").first?.split(separator: "/").last else {
                continue
            }
            let cleaned = String(name).replacingOccurrences(of: ".git", with: "")
            if testOnly.contains(cleaned) { continue }
            packages.append(cleaned)
        }
        return packages
    }

    private func repositoryRoot() -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url
    }
}
