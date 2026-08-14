import AnySSHCore
import Observation
import TerminalEmulator

@MainActor
@Observable
public final class BindingEditorModel {
    public struct ModifierChoice: Identifiable, Hashable, Sendable {
        public let id: String
        public let label: String
        public let modifier: KeyModifiers

        public init(id: String, label: String, modifier: KeyModifiers) {
            self.id = id
            self.label = label
            self.modifier = modifier
        }
    }

    public static let modifierChoices: [ModifierChoice] = [
        ModifierChoice(id: "none", label: "None", modifier: []),
        ModifierChoice(id: "control", label: "Ctrl", modifier: .control),
        ModifierChoice(id: "alt", label: "Alt", modifier: .alt),
        ModifierChoice(id: "shift", label: "Shift", modifier: .shift),
    ]

    public var text: String
    public var modifier: KeyModifiers

    public init(text: String = "", modifier: KeyModifiers = []) {
        self.text = text
        self.modifier = modifier
    }

    public convenience init(payload: ShortcutPanel.Entry.Payload) {
        switch payload {
        case .chord(let chordText):
            self.init(text: chordText)
        case .text(let literal):
            self.init(text: literal)
        }
    }

    public var preview: String? {
        BindingComposer.preview(modifier: modifier, text: text)
    }

    public var error: SimpleBindingSyntaxError? {
        BindingComposer.error(modifier: modifier, text: text)
    }

    public var canSave: Bool {
        preview != nil
    }

    public var composed: SimpleBinding? {
        BindingComposer.parse(modifier: modifier, text: text)
    }
}
