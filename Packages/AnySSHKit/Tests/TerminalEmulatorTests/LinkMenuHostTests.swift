import AnySSHCore
import Foundation
import Testing

@testable import TerminalEmulator

@Suite struct LinkMenuHostTests {
    @Test
    func openableSpanYieldsOpenOutcomeAndAddress() {
        let span = firstSpan(in: "Docs live at https://example.com/releases/latest")
        #expect(LinkSchemePolicy.outcome(for: span.url) == .open)
        #expect(span.url.absoluteString == "https://example.com/releases/latest")
        #expect(span.text == "https://example.com/releases/latest")
    }

    @Test
    func sshSpanIsRefusedAndStillCopyable() {
        let span = firstSpan(in: "Clone with ssh://git@example.com/anyssh/AnySSH.git")
        #expect(LinkSchemePolicy.outcome(for: span.url) == .refused(ErrorState.link(.schemeRefused)))
        #expect(span.url.absoluteString == "ssh://git@example.com/anyssh/AnySSH.git")
        #expect(ErrorState.link(.schemeRefused).stateID == "link.schemeRefused")
        #expect(ErrorState.link(.schemeRefused).copy.title == "Scheme refused")
    }

    @Test
    func hitTestOnFixtureDocsLineSelectsSpan() {
        let rows = [
            LinkRow(text: "Last login: Mon Aug 10 09:41:22 on ttys001", isWrapped: false),
            LinkRow(text: "dev@workstation ~ % git remote -v", isWrapped: false),
            LinkRow(text: "origin  https://github.com/anyssh/AnySSH.git (fetch)", isWrapped: false),
            LinkRow(text: "origin  https://github.com/anyssh/AnySSH.git (push)", isWrapped: false),
            LinkRow(text: "", isWrapped: false),
            LinkRow(text: "dev@workstation ~ % cat notes.txt", isWrapped: false),
            LinkRow(text: "Docs live at https://example.com/releases/latest", isWrapped: false),
            LinkRow(text: "Clone with ssh://git@example.com/anyssh/AnySSH.git", isWrapped: false),
        ]
        let spans = LinkScanner.scan(rows: rows)
        let hit = LinkHitTester.span(at: 6, column: 20, in: spans)
        #expect(hit?.text == "https://example.com/releases/latest")
        #expect(LinkHitTester.span(at: 0, column: 0, in: spans) == nil)
    }

    private func firstSpan(in text: String) -> LinkSpan {
        let spans = LinkScanner.scan(rows: [LinkRow(text: text, isWrapped: false)])
        precondition(!spans.isEmpty)
        return spans[0]
    }
}
