import AnySSHCore
import TerminalEmulator

enum AccessoryAction: Hashable, Sendable {
    case none
    case key(TerminalKey)
    case modifier(LatchedModifier)
    case chord(Chord)
    case prefix

    init(_ binding: AccessoryLayout.Binding) {
        switch binding.kind {
        case .none:
            self = .none
        case .key:
            guard let value = binding.value, let key = TerminalKey(name: value) else {
                self = .none
                return
            }
            self = .key(key)
        case .modifier:
            switch binding.value?.lowercased() {
            case "control", "ctrl": self = .modifier(.control)
            case "alt", "meta", "option": self = .modifier(.alt)
            case "shift": self = .modifier(.shift)
            default: self = .none
            }
        case .chord:
            guard let value = binding.value, let chord = try? Chord(parsing: value) else {
                self = .none
                return
            }
            self = .chord(chord)
        case .prefix:
            self = .prefix
        }
    }

    var label: String? {
        switch self {
        case .none: nil
        case .key(let key): KeyStroke(key).label
        case .modifier(let modifier): modifier.name
        case .chord(let chord): chord.label
        case .prefix: nil
        }
    }

    func bytes(using input: inout TerminalInput, prefixChordText: String) -> [UInt8] {
        switch self {
        case .none: return []
        case .key(let key): return input.send(key)
        case .modifier(let modifier):
            input.tap(modifier)
            return []
        case .chord(let chord): return input.send(chord)
        case .prefix:
            guard let chord = try? Chord(parsing: prefixChordText) else { return [] }
            return input.send(chord)
        }
    }
}

private extension LatchedModifier {
    var name: String {
        switch self {
        case .control: "Ctrl"
        case .alt: "Alt"
        case .shift: "Shift"
        }
    }
}
