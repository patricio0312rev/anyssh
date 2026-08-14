import TerminalEmulator

public struct HardwareKeyboardSession: Sendable {
    public var policy: HardwareKeyboardPolicy
    public var input: TerminalInput
    public private(set) var transportBytes = [UInt8]()
    public private(set) var shortcutLog = [AppShortcutEvent]()

    public init(
        policy: HardwareKeyboardPolicy = HardwareKeyboardPolicy(),
        input: TerminalInput = TerminalInput()
    ) {
        self.policy = policy
        self.input = input
    }

    public mutating func clearTransport() {
        transportBytes.removeAll(keepingCapacity: false)
    }

    public mutating func clearShortcuts() {
        shortcutLog.removeAll(keepingCapacity: false)
    }

    @discardableResult
    public mutating func press(
        keyCode: UInt16,
        control: Bool = false,
        alt: Bool = false,
        shift: Bool = false,
        command: Bool = false
    ) -> HardwareKeyRoute {
        guard let key = HardwareKeyCode(rawValue: keyCode) else { return .ignore }
        let modifiers = policy.wireModifiers(control: control, alt: alt, shift: shift)
        let route = policy.route(key: key, modifiers: modifiers, commandHeld: command)
        switch route {
        case .ignore:
            return .ignore
        case .appShortcut:
            return recordShortcut(
                key: key,
                command: command,
                shift: shift,
                control: control,
                alt: alt
            )
        case .transport:
            return encodeTransport(
                key: key,
                modifiers: modifiers,
                control: control,
                alt: alt,
                shift: shift,
                command: command
            )
        }
    }

    public mutating func send(_ key: TerminalKey) {
        transportBytes.append(contentsOf: input.send(key, modifiers: KeyModifiers()))
    }

    public mutating func pressesEnded() {}

    private mutating func recordShortcut(
        key: HardwareKeyCode,
        command: Bool,
        shift: Bool,
        control: Bool,
        alt: Bool
    ) -> HardwareKeyRoute {
        let event = AppShortcutEvent(
            key: key,
            command: command,
            shift: shift,
            control: control,
            alt: alt
        )
        shortcutLog.append(event)
        AppShortcutLog.shared.record(event)
        return .appShortcut
    }

    private mutating func encodeTransport(
        key: HardwareKeyCode,
        modifiers: KeyModifiers,
        control: Bool,
        alt: Bool,
        shift: Bool,
        command: Bool
    ) -> HardwareKeyRoute {
        guard let terminalKey = key.terminalKey(shift: shift) else { return .ignore }
        if command {
            if let kitty = KittyKeyEncoder.encode(
                key: terminalKey,
                control: control,
                alt: alt,
                shift: shift,
                command: true
            ) {
                transportBytes.append(contentsOf: kitty)
                return .transport
            }
            return recordShortcut(
                key: key,
                command: command,
                shift: shift,
                control: control,
                alt: alt
            )
        }
        let wireModifiers = shift ? modifiers.subtracting(.shift) : modifiers
        let bytes = input.send(terminalKey, modifiers: wireModifiers)
        transportBytes.append(contentsOf: bytes)
        return .transport
    }
}
