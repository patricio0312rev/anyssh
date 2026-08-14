extension UIIdentifier {
    public enum StatusToast {
        public static let host = "statusToast.host"
        public static let dismiss = "statusToast.dismiss"
        public static let action = "statusToast.action"

        public static func card(_ id: String) -> String {
            "statusToast.card.\(id)"
        }
    }
}
