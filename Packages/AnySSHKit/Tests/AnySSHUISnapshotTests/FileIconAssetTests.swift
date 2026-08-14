import Foundation
import Testing

@testable import AnySSHUI

@Suite struct FileIconAssetTests {
    @Test func everyMappedIconIsShipped() {
        let missing = FileIconResolver.mappedIconNames.subtracting(FileIconResolver.shippedIconNames)
        #expect(missing.isEmpty, "mapped icons missing from allowlist: \(missing.sorted())")
    }

    @Test func everyShippedIconHasAnImageset() throws {
        let catalog = try fileIconsCatalogURL()
        var missing: [String] = []
        for name in FileIconResolver.shippedIconNames.sorted() {
            let imageset = catalog.appendingPathComponent("\(name).imageset", isDirectory: true)
            let svg = imageset.appendingPathComponent("\(name).svg")
            let contents = imageset.appendingPathComponent("Contents.json")
            if !FileManager.default.fileExists(atPath: svg.path)
                || !FileManager.default.fileExists(atPath: contents.path)
            {
                missing.append(name)
            }
        }
        #expect(missing.isEmpty, "asset catalog missing imagesets: \(missing)")
    }

    @Test func catalogContainsOnlyAllowlistedImagesets() throws {
        let catalog = try fileIconsCatalogURL()
        let imagesets = try FileManager.default.contentsOfDirectory(atPath: catalog.path)
            .filter { $0.hasSuffix(".imageset") }
            .map { String($0.dropLast(".imageset".count)) }
        let unexpected = Set(imagesets).subtracting(FileIconResolver.shippedIconNames)
        #expect(unexpected.isEmpty, "unexpected imagesets: \(unexpected.sorted())")
        #expect(imagesets.count == FileIconResolver.shippedIconNames.count)
    }

    @Test func attributionCarriesTheMITNotice() {
        #expect(FileIconAttribution.notice.contains("Copyright (c) 2025 Material Extensions"))
        #expect(FileIconAttribution.notice.contains("Permission is hereby granted, free of charge"))
        #expect(FileIconAttribution.notice.contains("THE SOFTWARE IS PROVIDED \"AS IS\""))
        #expect(FileIconAttribution.sourceURL.contains("material-extensions/vscode-material-icon-theme"))
    }

    @Test func attributionFileMatchesNotice() throws {
        let url = try resourcesRoot().appendingPathComponent("FileIcons.ATTRIBUTION.txt")
        let text = try String(contentsOf: url, encoding: .utf8)
        #expect(text.contains("Copyright (c) 2025 Material Extensions"))
        #expect(text.contains("The MIT License (MIT)"))
        #expect(text.contains("material-extensions/vscode-material-icon-theme"))
    }

    @Test func stubProviderCoversEveryShippedName() {
        let provider = StubFileIconImageProvider()
        for name in FileIconResolver.shippedIconNames {
            #expect(provider.image(for: FileIconName(name)) != nil)
        }
        #expect(provider.image(for: FileIconName("not-a-real-icon")) == nil)
    }

    private func fileIconsCatalogURL() throws -> URL {
        try resourcesRoot().appendingPathComponent("FileIcons.xcassets", isDirectory: true)
    }

    private func resourcesRoot() throws -> URL {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 {
            url.deleteLastPathComponent()
        }
        let resources = url.appendingPathComponent("AnySSH/Resources", isDirectory: true)
        guard FileManager.default.fileExists(atPath: resources.path) else {
            Issue.record("AnySSH/Resources not found from \(#filePath)")
            throw CatalogLookupError.missingResources
        }
        return resources
    }
}

private enum CatalogLookupError: Error {
    case missingResources
}
