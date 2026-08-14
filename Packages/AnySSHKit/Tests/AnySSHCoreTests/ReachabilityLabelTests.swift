import Testing

@testable import AnySSHCore

@Suite struct ReachabilityLabelTests {
    @Test func everyPresentationHasADistinctNonEmptyLabel() {
        let labels = ReachabilityPresentation.allCases.map(\.accessibilityLabel)
        for label in labels {
            #expect(!label.isEmpty)
        }
        #expect(Set(labels).count == labels.count)
    }

    @Test func everyPresentationHasADistinctSymbol() {
        let symbols = ReachabilityPresentation.allCases.map(\.symbolName)
        for symbol in symbols {
            #expect(!symbol.isEmpty)
        }
        #expect(Set(symbols).count == symbols.count)
    }

    @Test func reachabilityMapsOntoPresentation() {
        #expect(ReachabilityPresentation(.reachable) == .reachable)
        #expect(ReachabilityPresentation(.unreachable) == .unreachable)
        #expect(ReachabilityPresentation(.unknown) == .unknown)
    }

    @Test func fourMockStatesAreCovered() {
        #expect(ReachabilityPresentation.allCases.count == 4)
        #expect(
            Set(ReachabilityPresentation.allCases)
                == [.checking, .reachable, .unreachable, .unknown]
        )
    }
}
