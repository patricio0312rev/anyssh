import CSSH

extension SSHSession {
    func lastErrorMessage() -> String {
        guard let handle else { return "" }
        var text: UnsafeMutablePointer<CChar>?
        var length: Int32 = 0
        libssh2_session_last_error(handle, &text, &length, 0)
        guard let text else { return "" }
        return String(cString: text)
    }
}
