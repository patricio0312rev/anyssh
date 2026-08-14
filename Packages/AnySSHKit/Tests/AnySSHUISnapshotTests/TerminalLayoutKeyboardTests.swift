import Testing

@testable import AnySSHUI

@Suite(.serialized) struct TerminalLayoutKeyboardTests {
    @Test func controlCProducesExactlyEtx() {
        var session = HardwareKeyboardSession()
        AppShortcutLog.shared.clear()

        let route = session.press(keyCode: HardwareKeyCode.c.rawValue, control: true)

        #expect(route == .transport)
        #expect(session.transportBytes == [0x03])
        #expect(session.shortcutLog.isEmpty)
        #expect(AppShortcutLog.shared.entries.isEmpty)
    }

    @Test func altFProducesEscapeFWhenOptionIsMeta() {
        var session = HardwareKeyboardSession(
            policy: HardwareKeyboardPolicy(optionAsMetaKey: true)
        )

        let route = session.press(keyCode: HardwareKeyCode.f.rawValue, alt: true)

        #expect(route == .transport)
        #expect(session.transportBytes == [0x1b, 0x66])
    }

    @Test func altFIsPlainFWhenOptionIsNotMeta() {
        var session = HardwareKeyboardSession(
            policy: HardwareKeyboardPolicy(optionAsMetaKey: false)
        )

        let route = session.press(keyCode: HardwareKeyCode.f.rawValue, alt: true)

        #expect(route == .transport)
        #expect(session.transportBytes == [0x66])
    }

    @Test func commandNFallsThroughWithZeroTransportBytes() {
        var session = HardwareKeyboardSession()
        AppShortcutLog.shared.clear()

        let route = session.press(keyCode: HardwareKeyCode.n.rawValue, command: true)

        #expect(route == .appShortcut)
        #expect(session.transportBytes.isEmpty)
        #expect(session.shortcutLog.map(\.label) == ["Cmd+N"])
        #expect(AppShortcutLog.shared.contains("Cmd+N"))
    }

    @Test func commandNReachesTheTransportWhenKittyIsActive() {
        var session = HardwareKeyboardSession(
            policy: HardwareKeyboardPolicy(kittyKeyboardActive: true)
        )
        AppShortcutLog.shared.clear()

        let route = session.press(keyCode: HardwareKeyCode.n.rawValue, command: true)

        #expect(route == .transport)
        #expect(session.transportBytes == Array("\u{1b}[110;9u".utf8))
        #expect(AppShortcutLog.shared.entries.isEmpty)
    }

    @Test func kittyCommandOnAnUnsupportedKeyFallsThroughToTheShortcutLog() {
        var session = HardwareKeyboardSession(
            policy: HardwareKeyboardPolicy(kittyKeyboardActive: true)
        )
        AppShortcutLog.shared.clear()

        let route = session.press(keyCode: HardwareKeyCode.right.rawValue, command: true)

        #expect(route == .appShortcut)
        #expect(session.transportBytes.isEmpty)
        #expect(session.shortcutLog.map(\.label) == ["Cmd+Right"])
    }

    @Test func shiftOneEncodesExclamation() {
        var session = HardwareKeyboardSession()

        let route = session.press(keyCode: HardwareKeyCode.one.rawValue, shift: true)

        #expect(route == .transport)
        #expect(session.transportBytes == [0x21])
    }

    @Test func shiftMinusEncodesUnderscore() {
        var session = HardwareKeyboardSession()

        let route = session.press(keyCode: HardwareKeyCode.minus.rawValue, shift: true)

        #expect(route == .transport)
        #expect(session.transportBytes == [0x5f])
    }

    @Test func axeKeyCodesMatchTheHidTable() {
        #expect(HardwareKeyCode.n.rawValue == 17)
        #expect(HardwareKeyCode.c.rawValue == 6)
        #expect(HardwareKeyCode.f.rawValue == 9)
        #expect(HardwareKeyCode.leftCommand.rawValue == 227)
        #expect(HardwareKeyCode.leftControl.rawValue == 224)
        #expect(HardwareKeyCode.leftAlt.rawValue == 226)
    }
}
