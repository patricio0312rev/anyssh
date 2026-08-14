import Foundation

@testable import TerminalEmulator

enum LinkScannerTable {
    static let cases: [LinkScannerCase] = positives + wrapped + zeros

    private static let positives: [LinkScannerCase] = [
        .init(
            "bare https",
            text: "https://example.com",
            expected: [.init("https://example.com", columns: 0..<19)]
        ),
        .init(
            "bare http",
            text: "http://example.com/a",
            expected: [.init("http://example.com/a", columns: 0..<20)]
        ),
        .init(
            "in parentheses",
            text: "see (https://example.com/docs) please",
            expected: [.init("https://example.com/docs", columns: 5..<29)]
        ),
        .init(
            "ending a sentence",
            text: "Read https://example.com/guide.",
            expected: [.init("https://example.com/guide", columns: 5..<30)]
        ),
        .init(
            "trailing comma",
            text: "go https://a.co/x, then stop",
            expected: [.init("https://a.co/x", columns: 3..<17)]
        ),
        .init(
            "trailing quote",
            text: "\"https://example.com/q\"",
            expected: [.init("https://example.com/q", columns: 1..<22)]
        ),
        .init(
            "trailing angle",
            text: "<https://example.com/a>",
            expected: [.init("https://example.com/a", columns: 1..<22)]
        ),
        .init(
            "ssh found",
            text: "ssh://git@example.com/anyssh/AnySSH.git",
            expected: [.init("ssh://git@example.com/anyssh/AnySSH.git", columns: 0..<39)]
        ),
        .init(
            "file path",
            text: "file:///Users/dev/src/anyssh",
            expected: [.init("file:///Users/dev/src/anyssh", columns: 0..<35)]
        ),
        .init(
            "balanced paren inside path",
            text: "https://en.wikipedia.org/wiki/Foo_(bar)",
            expected: [.init("https://en.wikipedia.org/wiki/Foo_(bar)", columns: 0..<39)]
        ),
        .init(
            "query and fragment",
            text: "https://example.com/a?x=1&y=2#top",
            expected: [.init("https://example.com/a?x=1&y=2#top", columns: 0..<33)]
        ),
        .init(
            "two urls one row",
            text: "https://a.example https://b.example",
            expected: [
                .init("https://a.example", columns: 0..<17),
                .init("https://b.example", columns: 18..<35),
            ]
        ),
        .init(
            "port and userinfo",
            text: "https://user:pass@host.example:8443/p",
            expected: [.init("https://user:pass@host.example:8443/p", columns: 0..<37)]
        ),
        .init(
            "bracket path kept",
            text: "https://example.com/a[1]",
            expected: [.init("https://example.com/a[1]", columns: 0..<24)]
        ),
        .init(
            "surrounded by brackets",
            text: "[https://example.com/x]",
            expected: [.init("https://example.com/x", columns: 1..<22)]
        ),
        .init(
            "fixture docs line",
            text: "Docs live at https://example.com/releases/latest",
            expected: [.init("https://example.com/releases/latest", columns: 13..<48)]
        ),
        .init(
            "fixture clone line",
            text: "Clone with ssh://git@example.com/anyssh/AnySSH.git",
            expected: [.init("ssh://git@example.com/anyssh/AnySSH.git", columns: 11..<50)]
        ),
        .init(
            "percent encoded",
            text: "https://example.com/a%20b",
            expected: [.init("https://example.com/a%20b", columns: 0..<25)]
        ),
        .init(
            "ipv6 host",
            text: "http://[2001:db8::1]/",
            expected: [.init("http://[2001:db8::1]/", columns: 0..<21)]
        ),
        .init(
            "mixed case scheme",
            text: "HTTPS://Example.COM/Path",
            expected: [.init("HTTPS://Example.COM/Path", columns: 0..<24)]
        ),
    ]

    private static let wrapped: [LinkScannerCase] = [
        .init(
            "wrapped two rows at 80",
            rows: [
                LinkRow(
                    text: String(repeating: " ", count: 40)
                        + "https://example.com/very/long/path/segme",
                    isWrapped: false
                ),
                LinkRow(text: "nt/continues-here", isWrapped: true),
            ],
            expected: [
                .init(
                    "https://example.com/very/long/path/segment/continues-here",
                    segments: [
                        LinkSegment(row: 0, columnRange: 40..<80),
                        LinkSegment(row: 1, columnRange: 0..<17),
                    ]
                )
            ]
        ),
        .init(
            "wrapped three rows",
            rows: [
                LinkRow(text: String(repeating: " ", count: 60) + "https://examp", isWrapped: false),
                LinkRow(text: "le.com/part-two/more-path/and-stil", isWrapped: true),
                LinkRow(text: "l-going", isWrapped: true),
            ],
            expected: [
                .init(
                    "https://example.com/part-two/more-path/and-still-going",
                    segments: [
                        LinkSegment(row: 0, columnRange: 60..<73),
                        LinkSegment(row: 1, columnRange: 0..<34),
                        LinkSegment(row: 2, columnRange: 0..<7),
                    ]
                )
            ]
        ),
        .init(
            "hard break is two candidates not one",
            rows: [
                LinkRow(text: "https://example.com/one", isWrapped: false),
                LinkRow(text: "https://example.com/two", isWrapped: false),
            ],
            expected: [
                .init("https://example.com/one", row: 0, columns: 0..<23),
                .init("https://example.com/two", row: 1, columns: 0..<23),
            ]
        ),
    ]

    private static let zeros: [LinkScannerCase] = [
        .init("empty", text: "", expected: []),
        .init("plain words", text: "no links here at all", expected: []),
        .init("scheme alone", text: "https://", expected: []),
        .init("missing host", text: "https:///path", expected: []),
        .init("glued prefix", text: "xhttps://example.com", expected: []),
        .init("ftp refused detection", text: "ftp://example.com/a", expected: []),
        .init("www without scheme", text: "www.example.com/docs", expected: []),
        .init("mailto", text: "mailto:user@example.com", expected: []),
    ]
}
