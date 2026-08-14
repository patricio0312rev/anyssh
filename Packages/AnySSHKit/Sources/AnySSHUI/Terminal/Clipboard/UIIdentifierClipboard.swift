extension UIIdentifier.Terminal {
    public enum Clipboard {
        public static let pasteControl = "terminal.clipboard.paste"
        public static let copy = "terminal.clipboard.copy"
        public static let dismissHint = "terminal.clipboard.dismissHint"
        public static let selection = "terminal.clipboard.selection"
    }

    public enum Paste {
        public static let sheet = "terminal.paste.sheet"
        public static let lineCount = "terminal.paste.lineCount"
        public static let preview = "terminal.paste.preview"
        public static let confirm = "terminal.paste.confirm"
        public static let cancel = "terminal.paste.cancel"
    }
}
