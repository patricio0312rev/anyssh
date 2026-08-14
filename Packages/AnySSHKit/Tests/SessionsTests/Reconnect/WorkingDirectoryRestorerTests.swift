import AnySSHCore
import Foundation
import Testing

@testable import Sessions

@Suite struct WorkingDirectoryRestorerTests {
    private let restorer = WorkingDirectoryRestorer()

    @Test func returnsToTheRememberedDirectory() {
        let workspace = WorkspaceLocation(path: "/home/ci/work/anyssh", provenance: .process)

        #expect(
            restorer.payload(for: workspace).map { String(decoding: $0, as: UTF8.self) }
                == "cd '/home/ci/work/anyssh'\n"
        )
    }

    @Test func quotesAPathWithASpaceOrAQuote() {
        let workspace = WorkspaceLocation(path: "/home/ci/my work", provenance: .process)
        let rendered = restorer.payload(for: workspace).map { String(decoding: $0, as: UTF8.self) }

        #expect(rendered == "cd '/home/ci/my work'\n")
    }

    @Test func sendsNothingWhenNowhereIsRemembered() {
        #expect(restorer.payload(for: nil) == nil)
    }

    @Test func sendsNothingForHome() {
        #expect(restorer.payload(for: WorkspaceLocation(path: "~", provenance: .process)) == nil)
    }
}
