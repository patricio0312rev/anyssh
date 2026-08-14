import Foundation

extension UIIdentifier {
    public enum About {
        public static let screen = "about.screen"
        public static let version = "about.version"
        public static let noticeText = "about.notice.text"

        public static func link(_ title: String) -> String {
            "about.link.\(title.lowercased())"
        }

        public static func notice(_ resource: String) -> String {
            "about.notice.\(resource)"
        }
    }
}
