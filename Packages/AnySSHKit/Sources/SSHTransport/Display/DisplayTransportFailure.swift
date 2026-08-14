import AnySSHCore

extension TransportFailure {
    static func channelRejected(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.channelRejected", code: code, detail: detail)
    }

    static func ptyRejected(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.ptyRejected", code: code, detail: detail)
    }

    static func shellRejected(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.shellRejected", code: code, detail: detail)
    }

    static func resizeRejected(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.resizeRejected", code: code, detail: detail)
    }

    static let noSink = Self(stateID: "transport.noSink")

    static let alreadyStarted = Self(stateID: "transport.alreadyStarted")
}
