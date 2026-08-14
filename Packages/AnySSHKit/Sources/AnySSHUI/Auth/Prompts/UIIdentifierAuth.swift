extension UIIdentifier {
    public enum Auth {
        public static let sheet = "auth.prompt.sheet"
        public static let instruction = "auth.prompt.instruction"
        public static let submit = "auth.prompt.submit"
        public static let cancel = "auth.prompt.cancel"
        public static let savePassword = "auth.savePassword"
        public static let savePasswordConfirm = "auth.savePassword.confirm"
        public static let savePasswordSkip = "auth.savePassword.skip"

        public static func field(_ index: Int) -> String {
            "auth.prompt.field.\(index)"
        }
    }
}
