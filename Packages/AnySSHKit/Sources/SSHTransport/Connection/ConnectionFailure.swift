import AnySSHCore

extension TransportFailure {
    public static let cancelledBySwitch = Self(
        stateID: ErrorState.transport(.cancelledBySwitch).stateID
    )

    public static let connectionClosed = Self(stateID: "transport.connectionClosed")

    public static let controlResponseTooLarge = Self(
        stateID: ErrorState.command(.responseTooLarge).stateID,
        detail: "control"
    )

    static func execRejected(code: Int32, detail: String = "") -> Self {
        Self(stateID: "transport.channelRejected", code: code, detail: detail)
    }
}

extension TransportNote {
    public static func secondPromptRequired(transport: String) -> Self {
        Self(stateID: "transport.secondPromptRequired", detail: transport)
    }
}
