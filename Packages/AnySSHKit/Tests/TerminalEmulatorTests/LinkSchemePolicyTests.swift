import AnySSHCore
import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct LinkSchemePolicyTests {
    @Test
    func httpAndHttpsOpen() {
        #expect(LinkSchemePolicy.outcome(for: URL(string: "https://example.com")!) == .open)
        #expect(LinkSchemePolicy.outcome(for: URL(string: "http://example.com")!) == .open)
        #expect(LinkSchemePolicy.outcome(for: URL(string: "HTTPS://EXAMPLE.COM")!) == .open)
    }

    @Test
    func sshIsFoundButRefusedOnOpen() {
        let url = URL(string: "ssh://git@example.com/anyssh/AnySSH.git")!
        let rows = [LinkRow(text: url.absoluteString, isWrapped: false)]
        let spans = LinkScanner.scan(rows: rows)
        #expect(spans.count == 1)
        #expect(LinkSchemePolicy.outcome(for: spans[0].url) == .refused(ErrorState.link(.schemeRefused)))
    }

    @Test
    func fileIsFoundButRefusedOnOpen() {
        let url = URL(string: "file:///tmp/readme.txt")!
        let spans = LinkScanner.scan(rows: [LinkRow(text: url.absoluteString, isWrapped: false)])
        #expect(spans.count == 1)
        #expect(LinkSchemePolicy.outcome(for: spans[0].url) == .refused(ErrorState.link(.schemeRefused)))
    }

    @Test
    func openableSchemesAreHttpOnly() {
        #expect(LinkSchemePolicy.openableSchemes == ["http", "https"])
    }
}
