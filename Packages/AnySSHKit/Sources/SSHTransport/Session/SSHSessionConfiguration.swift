import CSSH
import Darwin

public struct SSHSessionConfiguration: Sendable {
    public var connectTimeout: Duration
    public var handshakeTimeout: Duration
    public var deadPeerTimeout: Duration
    public var keepaliveInterval: Duration
    public var wantsKeepaliveReply: Bool
    public var readBufferSize: Int
    public var io: SSHIOCallbacks?

    public init(
        connectTimeout: Duration = .seconds(10),
        handshakeTimeout: Duration = .seconds(20),
        deadPeerTimeout: Duration = .seconds(45),
        keepaliveInterval: Duration = .seconds(30),
        wantsKeepaliveReply: Bool = true,
        readBufferSize: Int = 32 * 1024,
        io: SSHIOCallbacks? = nil
    ) {
        self.connectTimeout = connectTimeout
        self.handshakeTimeout = handshakeTimeout
        self.deadPeerTimeout = deadPeerTimeout
        self.keepaliveInterval = keepaliveInterval
        self.wantsKeepaliveReply = wantsKeepaliveReply
        self.readBufferSize = readBufferSize
        self.io = io
    }
}

public final class SSHIOContext<Value>: @unchecked Sendable {
    private let storage: UnsafeMutablePointer<Value>

    public init(_ value: Value) {
        storage = .allocate(capacity: 1)
        storage.initialize(to: value)
    }

    deinit {
        storage.deinitialize(count: 1)
        storage.deallocate()
    }

    public var pointer: UnsafeMutableRawPointer {
        UnsafeMutableRawPointer(storage)
    }

    public var value: Value {
        storage.pointee
    }

    public func withValue<Result>(_ body: (inout Value) -> Result) -> Result {
        body(&storage.pointee)
    }
}

public struct SSHIOCallbacks: @unchecked Sendable {
    public typealias Receive =
        @convention(c) (
            libssh2_socket_t, UnsafeMutableRawPointer?, Int, Int32,
            UnsafeMutablePointer<UnsafeMutableRawPointer?>?
        ) -> Int

    public typealias Send =
        @convention(c) (
            libssh2_socket_t, UnsafeRawPointer?, Int, Int32,
            UnsafeMutablePointer<UnsafeMutableRawPointer?>?
        ) -> Int

    public let receive: Receive
    public let send: Send
    public let context: UnsafeMutableRawPointer?

    private let owner: AnyObject?

    public init<Value>(receive: @escaping Receive, send: @escaping Send, context: SSHIOContext<Value>) {
        self.receive = receive
        self.send = send
        self.context = context.pointer
        owner = context
    }

    public init(receive: @escaping Receive, send: @escaping Send) {
        self.receive = receive
        self.send = send
        context = nil
        owner = nil
    }
}

public struct SessionDiagnostics: Hashable, Sendable {
    public var eagainRetries = 0
    public var errorCodes = [Int32]()

    public init() {}
}
