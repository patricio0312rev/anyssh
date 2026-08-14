import Testing

@testable import TerminalEmulator

@Suite struct ScreenSizeTests {
    @Test func cellCountMultipliesDimensions() {
        #expect(ScreenSize.standard.cellCount == 1920)
    }

    @Test(arguments: [-4, 0]) func dimensionsAreClampedToOne(_ value: Int) {
        #expect(ScreenSize(columns: value, rows: value).cellCount == 1)
    }
}
