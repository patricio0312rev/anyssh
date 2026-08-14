public enum UIIdentifier {
    public enum Launch {
        public static let keychainMigrationRuns = "launch.keychainMigrationRuns"
    }

    public enum Session {
        public static let statusLabel = "session.statusLabel"
        public static let statusDot = "session.statusDot"
        public static let reconnect = "session.reconnect"
        public static let reconnectCard = "session.reconnectCard"
        public static let reconnectAttempts = "session.reconnectAttempts"
        public static let reattached = "session.reattached"
        public static let openFailure = "session.openFailure"
        public static let switchDurations = "session.switch.durations"
        public static let workspaceEmpty = "session.workspace.empty"
        public static let newSession = "session.workspace.newSession"
        public static let backToRemotes = "session.workspace.backToRemotes"
    }

    public enum Terminal {
        public static let canvas = "terminal.canvas"
        public static let dismissKeyboard = "terminal.keyboard.dismiss"
    }

    public enum Workspace {
        public static let wrapToggle = "workspace.files.preview.wrap"
    }
}
