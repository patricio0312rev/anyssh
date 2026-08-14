import Testing

@testable import AnySSHUI

@Suite struct RendererSelectionTests {
    init() {
        TerminalMetalLibrary.lift()
    }

    @Test func metalAndCoreTextRenderTheSameScreen() {
        let metal = TerminalFixture.engine(renderer: .metal)
        let coreText = TerminalFixture.engine(renderer: .coreText)

        metal.activateRenderer()
        #expect(coreText.activateRenderer() == .coreText)
        #expect(metal.describeScreen() == coreText.describeScreen())
        #expect(metal.describeScreen().contains("Darwin 25.5.0"))
        #expect(metal.size.columns == 80)
        #expect(metal.size.rows == 24)
        #expect(metal.size.pixelWidth > 0)
    }

    @Test func aMetalRequestReportsTheRendererThatTookEffect() {
        let engine = TerminalFixture.engine(renderer: .metal)

        #expect(engine.preferredRenderer == .metal)
        #expect(engine.activeRenderer == .coreText)
        let active = engine.activateRenderer()
        #expect(engine.activeRenderer == active)
        #if os(macOS)
        #expect(active == .coreText)
        #expect(engine.rendererFallbackReason != nil)
        #else
        #expect(active == .metal)
        #expect(engine.rendererFallbackReason == nil)
        #endif
    }

    @Test func forcingCoreTextKeepsTheFallbackLive() {
        let engine = TerminalFixture.engine(renderer: .coreText)

        #expect(engine.activateRenderer() == .coreText)
        #expect(engine.activeRenderer == .coreText)
        #expect(engine.describeScreen().contains("Build complete!"))
    }

    @Test func theBufferingModeDefaultsToPerRowAndSwitchesAtRuntime() {
        let engine = TerminalFixture.engine(renderer: .metal)

        #expect(engine.bufferingMode == .perRowPersistent)
        engine.bufferingMode = .perFrameAggregated
        #expect(engine.bufferingMode == .perFrameAggregated)
    }
}
