import Foundation
import Testing

@testable import AnySSHCore

private struct DocumentRow: Hashable {
    let stateID: String
    let accessibilityIdentifier: String
    let title: String
    let body: String
    let recoveryLabel: String
    let owningPhase: Int
    let artifactPath: String

    init?(cells: [String]) {
        guard cells.count == 7, let phase = Int(cells[5]) else { return nil }
        stateID = cells[0]
        accessibilityIdentifier = cells[1]
        title = cells[2]
        body = cells[3]
        recoveryLabel = cells[4]
        owningPhase = phase
        artifactPath = cells[6]
    }
}

private enum RegistryDocument {
    static let url = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "docs/error-states.md")

    static func rows() throws -> [DocumentRow] {
        let text = try String(contentsOf: url, encoding: .utf8)
        return text.split(separator: "\n")
            .filter { $0.hasPrefix("| `") }
            .compactMap { DocumentRow(cells: cells(of: $0)) }
    }

    private static func cells(of line: Substring) -> [String] {
        line.split(separator: "|", omittingEmptySubsequences: false)
            .dropFirst()
            .dropLast()
            .map {
                $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "`", with: "")
            }
    }
}

@Suite struct ErrorStateTests {
    @Test func everyCaseHasARowAndEveryRowHasACase() throws {
        let documented = Set(try RegistryDocument.rows().map(\.stateID))
        let declared = Set(ErrorState.allCases.map(\.stateID))

        #expect(
            declared.subtracting(documented).isEmpty,
            "cases missing from docs/error-states.md: \(declared.subtracting(documented).sorted())"
        )
        #expect(
            documented.subtracting(declared).isEmpty,
            "rows with no case: \(documented.subtracting(declared).sorted())"
        )
    }

    @Test func everyRowMatchesTheCopyItsCaseDeclares() throws {
        let rows = Dictionary(uniqueKeysWithValues: try RegistryDocument.rows().map { ($0.stateID, $0) })

        for state in ErrorState.allCases {
            guard let row = rows[state.stateID] else { continue }
            #expect(row.title == state.copy.title, "title drift on \(state.stateID)")
            #expect(row.body == state.copy.body, "body drift on \(state.stateID)")
            #expect(
                row.recoveryLabel == state.copy.recoveryLabel,
                "recovery label drift on \(state.stateID)"
            )
            #expect(
                row.accessibilityIdentifier == state.accessibilityIdentifier,
                "identifier drift on \(state.stateID)"
            )
            #expect(row.owningPhase == state.owningPhase, "owning phase drift on \(state.stateID)")
            #expect(row.artifactPath == state.artifactPath, "artifact path drift on \(state.stateID)")
        }
    }

    @Test func stateIDsAreUniqueAndWellFormed() {
        let ids = ErrorState.allCases.map(\.stateID)
        #expect(Set(ids).count == ids.count, "duplicate stateIDs in \(ids)")

        let pattern = /^[a-z]+\.[a-z][a-zA-Z]+$/
        let malformed = ids.filter { $0.wholeMatch(of: pattern) == nil }
        #expect(malformed.isEmpty, "stateIDs failing ^[a-z]+\\.[a-z][a-zA-Z]+$: \(malformed)")
    }

    @Test func documentRowsAreUnique() throws {
        let ids = try RegistryDocument.rows().map(\.stateID)
        #expect(Set(ids).count == ids.count, "duplicate rows in docs/error-states.md")
    }

    @Test func everyStateResolvesFromItsIdentifier() {
        for state in ErrorState.allCases {
            #expect(ErrorState(stateID: state.stateID) == state)
        }
        #expect(ErrorState(stateID: "trust.noSuchState") == nil)
        #expect(ErrorState(stateID: "") == nil)
    }

    @Test func identifiersAndArtifactPathsDeriveFromTheStateID() {
        for state in ErrorState.allCases {
            #expect(state.accessibilityIdentifier == "error.\(state.stateID)")
            #expect(state.artifactPath == ".build/artifacts/errors/\(state.stateID).png")
            #expect(state.stateID.hasPrefix("\(state.group.rawValue)."))
        }
    }

    @Test func everyGroupIsPopulated() {
        for group in ErrorStateGroup.allCases {
            #expect(
                ErrorState.allCases.contains { $0.group == group },
                "no state in group \(group.rawValue)"
            )
        }
    }

    @Test func copyStaysInTone() {
        let apologies = ["sorry", "oops", "whoops", "unfortunately"]

        for state in ErrorState.allCases {
            let copy = state.copy
            #expect(copy.title.isEmpty == false, "empty title on \(state.stateID)")
            #expect(copy.title.hasSuffix(".") == false, "title ends in a period on \(state.stateID)")
            #expect(copy.body.hasSuffix("."), "body does not end in a period on \(state.stateID)")
            #expect(copy.recoveryLabel.isEmpty == false, "empty recovery label on \(state.stateID)")
            #expect(copy.recoveryLabel.count <= 20, "recovery label too long on \(state.stateID)")

            for text in [copy.title, copy.body, copy.recoveryLabel] {
                #expect(text.contains("!") == false, "exclamation mark in \(state.stateID)")
                #expect(text.contains("|") == false, "pipe breaks the table row for \(state.stateID)")
                #expect(
                    text.trimmingCharacters(in: .whitespaces) == text,
                    "padded copy in \(state.stateID)"
                )
                #expect(
                    apologies.contains(where: text.lowercased().contains) == false,
                    "apology in \(state.stateID)"
                )
            }
        }
    }
}
