import Foundation

extension UIIdentifier {
    public enum Settings {
        public static let open = "settings.open"
        public static let screen = "settings.screen"
        public static let close = "settings.close"
        public static let gestures = "settings.gestures"
        public static let gesturesScreen = "settings.gestures.screen"
        public static let gesturesReset = "settings.gestures.reset"
        public static let snippets = "settings.snippets"
        public static let snippetsScreen = "settings.snippets.screen"
        public static let about = "settings.about"
        public static let privacy = "settings.privacy"
        public static let privacyScreen = "settings.privacy.screen"
        public static let title = "settings.title"
        public static let titleScreen = "settings.title.screen"
        public static let titlePreviewBar = "settings.title.preview"

        public static func gestureRow(_ slot: String) -> String {
            "settings.gestures.row.\(slot)"
        }

        public static func titleMode(_ mode: String) -> String {
            "settings.title.mode.\(mode)"
        }

        public static func titlePreview(_ mode: String) -> String {
            "settings.title.preview.\(mode)"
        }
    }
}
