extension UIIdentifier {
    public enum Remote {
        public static let list = "remote.list"
        public static let empty = "remote.list.empty"
        public static let loading = "remote.list.loading"
        public static let add = "remote.list.add"
        public static let edit = "remote.list.edit"

        public static let emptyAddHost = "remote.empty.addHost"
        public static let emptyImportKey = "remote.empty.importKey"

        public static let deleteConfirm = "remote.delete.confirm"
        public static let deleteCancel = "remote.delete.cancel"

        public static func row(_ id: String) -> String {
            "remote.row.\(id)"
        }

        public static func delete(_ id: String) -> String {
            "remote.row.\(id).delete"
        }

        public static func editRow(_ id: String) -> String {
            "remote.row.\(id).edit"
        }

        public static func reachability(_ id: String) -> String {
            "remote.row.\(id).reachability"
        }
    }

    public enum RemoteForm {
        public static let screen = "remote.form"
        public static let name = "remote.form.name"
        public static let host = "remote.form.host"
        public static let port = "remote.form.port"
        public static let username = "remote.form.username"
        public static let authMethod = "remote.form.authMethod"
        public static let deviceType = "remote.form.deviceType"
        public static let password = "remote.form.password"
        public static let testConnection = "remote.form.testConnection"
        public static let testResult = "remote.form.testResult"
        public static let startPath = "remote.form.startPath"
        public static let startupCommand = "remote.form.startupCommand"
        public static let tag = "remote.form.tag"
        public static let importKey = "remote.form.importKey"
        public static let keyImported = "remote.form.keyImported"
        public static let save = "remote.form.save"
        public static let cancel = "remote.form.cancel"

        public static func message(_ field: String) -> String {
            "\(field).message"
        }
    }
}
