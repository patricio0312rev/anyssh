import AnySSHCore

public enum ShortcutPanelIdentifier {
    public static let bar = "panel.bar"
    public static let bytes = "panel.bytes"
    public static let editor = "panel.editor"
    public static let editorText = "panel.editor.text"
    public static let editorPreview = "panel.editor.preview"
    public static let editorSave = "panel.editor.save"
    public static let editorCancel = "panel.editor.cancel"
    public static let addCustomEntry = "panel.custom.add"

    public static func tab(_ scope: ShortcutPanel.Scope) -> String {
        "panel.tab.\(scope.rawValue)"
    }

    public static func panel(_ scope: ShortcutPanel.Scope) -> String {
        "panel.\(scope.rawValue)"
    }

    public static func entry(_ entry: ShortcutPanel.Entry, scope: ShortcutPanel.Scope) -> String {
        "panel.\(scope.rawValue).\(entry.id)"
    }

    public static func modifier(_ name: String) -> String {
        "panel.editor.modifier.\(name)"
    }
}
