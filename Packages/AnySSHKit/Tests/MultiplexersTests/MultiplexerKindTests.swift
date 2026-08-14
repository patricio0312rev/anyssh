import Testing

@testable import Multiplexers

@Suite struct MultiplexerKindTests {
    @Test func coversTheMultiplexersTheMVPSupports() {
        #expect(Set(MultiplexerKind.allCases) == [.none, .tmux, .herdr])
    }

    @Test func rawValuesArePersistableIdentifiers() {
        #expect(MultiplexerKind(rawValue: "herdr") == .herdr)
        #expect(MultiplexerKind(rawValue: "screen") == nil)
    }
}
