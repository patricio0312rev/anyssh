import AnySSHCore

public struct HostKeyQuestion: Sendable {
    public typealias Ask = @Sendable (HostKey, KnownHostStatus) async -> HostKeyVerdict

    private let ask: Ask

    public init(_ ask: @escaping Ask) {
        self.ask = ask
    }

    public func callAsFunction(_ key: HostKey, _ status: KnownHostStatus) async -> HostKeyVerdict {
        await ask(key, status)
    }

    public static func delegate(
        _ delegate: any TerminalTransportDelegate,
        of transport: any TerminalTransport
    ) -> HostKeyQuestion {
        HostKeyQuestion { key, status in
            await delegate.transport(transport, verify: key, status: status)
        }
    }

    public static let unattended = HostKeyQuestion { _, _ in .cancel }
}
