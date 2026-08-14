import AnySSHCore
import TerminalEmulator
import Testing

@testable import AnySSHUI

@Suite @MainActor struct AccessoryBindingFlowTests {
    @Test func tapDoubleTapAndLongPressUseTheSameKeyBindings() async {
        let key = AccessoryLayout.Key(
            id: "terminal.accessory.key.binding-test",
            label: "B",
            tap: .key("a"),
            doubleTap: .key("b"),
            longPress: .key("c")
        )
        let transport = AccessoryRecordingTransport()
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: [key]), writer: transport)

        await model.activate(key.tap)
        await model.activate(key.doubleTap)
        await model.activate(key.longPress)

        #expect(await transport.writes == [[0x61], [0x62], [0x63]])
    }

    @Test func controlLatchSendsControlCThroughTheAccessoryModel() async {
        let control = AccessoryLayout.defaults.keys[2]
        let c = AccessoryLayout.Key(
            id: "terminal.accessory.key.c",
            label: "C",
            tap: .key("c")
        )
        let transport = AccessoryRecordingTransport()
        let model = AccessoryBarModel(
            layout: AccessoryLayout(keys: [control, c]),
            writer: transport
        )

        await model.activate(control.tap)
        #expect(model.input.preview == "^")
        await model.activate(c.tap)

        #expect(await transport.writes == [[0x03]])
        #expect(model.input.preview.isEmpty)
    }

    @Test func chordBindingReportsItsPreviewLabel() {
        let key = AccessoryLayout.Key(
            id: "terminal.accessory.key.chord",
            label: "Save",
            tap: .chord("C-c")
        )
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: [key]))

        #expect(model.title(for: key) == "^C")
    }

    @Test func prefixKeyFallsBackToCtrlBWithoutDiscovery() async {
        let prefix = AccessoryLayout.prefixKey
        let transport = AccessoryRecordingTransport()
        let model = AccessoryBarModel(
            layout: AccessoryLayout(keys: [prefix]),
            writer: transport
        )

        #expect(model.title(for: prefix) == "PRE")
        await model.activate(prefix.tap)

        #expect(await transport.writes == [[0x02]])
    }

    @Test func prefixKeyEmitsTheDiscoveredPrefix() async {
        let prefix = AccessoryLayout.prefixKey
        let transport = AccessoryRecordingTransport()
        let model = AccessoryBarModel(
            layout: AccessoryLayout(keys: [prefix]),
            writer: transport,
            bindings: MuxKeyBindings(prefix: "ctrl+a", chords: [:])
        )

        #expect(model.title(for: prefix) == "PRE")
        await model.activate(prefix.tap)

        #expect(await transport.writes == [[0x01]])
    }
}

private actor AccessoryRecordingTransport: DisplayWriter {
    private(set) var writes = [[UInt8]]()

    func send(_ bytes: ArraySlice<UInt8>) async throws {
        writes.append(Array(bytes))
    }
}
