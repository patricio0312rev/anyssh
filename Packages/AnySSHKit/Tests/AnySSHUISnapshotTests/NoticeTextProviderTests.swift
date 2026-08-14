import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@Suite struct NoticeTextProviderTests {
    private static let notice = ThirdPartyNotice(
        name: "libssh2",
        licence: "BSD-3-Clause",
        url: "https://libssh2.org",
        resource: "licence-libssh2"
    )

    @Test func aCollectedNoticeIsReadFromTheBundleThatShippedIt() throws {
        let directory = try Self.directory()
        try "Copyright (c) the libssh2 project".write(
            to: directory.appending(path: "\(Self.notice.resource).txt"),
            atomically: true,
            encoding: .utf8
        )
        let bundle = try #require(Bundle(url: directory))

        let text = BundleNoticeTextProvider(bundle: bundle).text(of: Self.notice)

        #expect(text == "Copyright (c) the libssh2 project")
    }

    @Test func aNoticeThatDidNotShipReadsAsMissingRatherThanEmpty() throws {
        let bundle = try #require(Bundle(url: try Self.directory()))

        #expect(BundleNoticeTextProvider(bundle: bundle).text(of: Self.notice) == nil)
    }

    @Test func theDefaultProviderAnswersNothingForEveryNotice() {
        let provider = EmptyNoticeTextProvider()

        for notice in ThirdPartyNotices.all {
            #expect(provider.text(of: notice) == nil)
        }
    }

    private static func directory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: "notices-\(UUID().uuidString).bundle")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
