import AnySSHCore
import TerminalEmulator
import Testing

@testable import AnySSHUI

@Suite @MainActor struct AccessoryLatchTests {
    @Test func ctrlThenATypedLetterProducesTheControlCode() async {
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: []))
        _ = model.input.latch
        await model.activate(AccessoryLayout.Binding(kind: .modifier, value: "control"))

        #expect(model.applyLatch(to: Array("c".utf8)[...]) == [0x03])
    }

    @Test func theLatchIsSpentOnOneKey() async {
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: []))
        await model.activate(AccessoryLayout.Binding(kind: .modifier, value: "control"))

        _ = model.applyLatch(to: Array("c".utf8)[...])

        #expect(model.applyLatch(to: Array("c".utf8)[...]) == Array("c".utf8))
    }

    @Test func textWithNoLatchIsUntouched() {
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: []))

        #expect(model.applyLatch(to: Array("ls -la".utf8)[...]) == Array("ls -la".utf8))
    }

    @Test func aMultiCharacterRunIsUntouchedEvenWhileLatched() async {
        let model = AccessoryBarModel(layout: AccessoryLayout(keys: []))
        await model.activate(AccessoryLayout.Binding(kind: .modifier, value: "control"))

        #expect(model.applyLatch(to: Array("git status".utf8)[...]) == Array("git status".utf8))
    }
}
