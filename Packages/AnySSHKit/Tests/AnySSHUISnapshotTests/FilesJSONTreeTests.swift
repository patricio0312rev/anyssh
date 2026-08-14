import AnySSHCore
import Foundation
import Testing

@testable import AnySSHUI

@Suite @MainActor struct FilesJSONTreeTests {
    private static let megabyte = 1024 * 1024

    @Test func parserPreservesAuthorKeyOrder() throws {
        let root = try JSONTextParser.parse(#"{"beta": 1, "alpha": 2, "gamma": 3}"#)

        guard case .object(let children) = root else {
            Issue.record("expected object")
            return
        }
        #expect(children.map(\.key) == ["beta", "alpha", "gamma"])
    }

    @Test func parserRoundTripsThroughThePrinter() throws {
        let source = #"{"s":"a\"b\nc\u00e9\ud83d\ude00","n":-12.5e2,"b":true,"z":null,"a":[1,"x"],"o":{}}"#
        let first = try JSONTextParser.parse(source)
        let printed = JSONPrettyPrinter.print(first)
        let second = try JSONTextParser.parse(printed)

        #expect(first == second)
        #expect(printed.contains("\n"), "pretty output must be multi-line")
    }

    @Test func printerSortsKeysOnlyWhenAsked() throws {
        let root = try JSONTextParser.parse(#"{"zeta": 1, "alpha": 2}"#)

        let sorted = JSONPrettyPrinter.print(root, sortedKeys: true)
        let unsorted = JSONPrettyPrinter.print(root, sortedKeys: false)

        let sortedAlpha = try #require(sorted.range(of: "\"alpha\""))
        let sortedZeta = try #require(sorted.range(of: "\"zeta\""))
        #expect(sortedAlpha.lowerBound < sortedZeta.lowerBound)

        let unsortedZeta = try #require(unsorted.range(of: "\"zeta\""))
        let unsortedAlpha = try #require(unsorted.range(of: "\"alpha\""))
        #expect(unsortedZeta.lowerBound < unsortedAlpha.lowerBound)
    }

    @Test func fiveMegabyteMinifiedFixtureStaysLazy() throws {
        let itemCount = 80_000
        let fixture = try Self.minifiedFixture(itemCount: itemCount)
        #expect(fixture.utf8.count >= 5 * Self.megabyte, "fixture must be at least 5 MB")
        #expect(!fixture.contains("\n"), "fixture must be a single line")

        let root = try JSONTextParser.parse(fixture)
        var model = JSONTreeModel(root: root)

        #expect(model.visibleRowCount == 1, "collapsed root implies exactly one visible row")

        let rootRow = model.row(at: 0)
        model.expand(rootRow.id)
        #expect(model.visibleRowCount == 4, "root object has three children")

        let itemsRow = model.row(at: 2)
        model.expand(itemsRow.id)
        #expect(model.visibleRowCount == 4 + itemCount, "expanding items splices every child in")

        let firstItem = model.row(at: 3)
        model.expand(firstItem.id)
        #expect(model.visibleRowCount == 4 + itemCount + 4, "an item object has four children")

        model.collapse(itemsRow.id)
        #expect(model.visibleRowCount == 4, "collapse removes exactly the spliced subtree")
    }

    @Test func invalidJsonThrowsInsteadOfCrashing() {
        #expect(throws: JSONTextParser.Failure.self) {
            try JSONTextParser.parse(#"{"unterminated": }"#)
        }
        #expect(throws: JSONTextParser.Failure.self) {
            try JSONTextParser.parse("12 34")
        }
    }

    private static func minifiedFixture(itemCount: Int) throws -> String {
        var text = #"{"version":1,"items":["#
        for index in 0..<itemCount {
            if index > 0 { text += "," }
            text += #"{"id":\#(index),"name":"item-\#(index)","tags":["a","b","c"],"meta":{"x":1,"y":2}}"#
        }
        text += #"],"summary":"done"}"#
        return text
    }
}
