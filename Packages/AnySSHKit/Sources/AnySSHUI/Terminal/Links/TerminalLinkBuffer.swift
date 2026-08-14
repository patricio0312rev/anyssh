import Foundation
import TerminalEmulator

public enum TerminalLinkBuffer {
    public static func rows(
        from screen: String,
        columns: Int = TerminalLinkFixture.columns
    ) -> [LinkRow] {
        let lines =
            screen
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
        var rows: [LinkRow] = []
        for line in lines {
            var rest = line
            var isFirst = true
            while rest.count > columns {
                let head = String(rest.prefix(columns))
                rows.append(LinkRow(text: head, isWrapped: !isFirst))
                rest = String(rest.dropFirst(columns))
                isFirst = false
            }
            rows.append(LinkRow(text: rest, isWrapped: !isFirst))
        }
        while rows.count < TerminalLinkFixture.rows {
            rows.append(LinkRow(text: "", isWrapped: false))
        }
        return Array(rows.prefix(TerminalLinkFixture.rows))
    }

    public static func spans(from screen: String = TerminalLinkFixture.screen) -> [LinkSpan] {
        LinkScanner.scan(rows: rows(from: screen))
    }
}
