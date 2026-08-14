import Foundation

enum TerminalWorkingDirectory {
    static func path(from payload: String) -> String? {
        guard let components = URLComponents(string: payload), components.scheme == "file" else {
            return payload.hasPrefix("/") ? payload : nil
        }
        let path = components.path
        return path.isEmpty ? nil : path
    }
}
