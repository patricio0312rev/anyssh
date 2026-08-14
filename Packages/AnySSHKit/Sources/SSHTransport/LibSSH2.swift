import CSSH

enum LibSSH2Library {
    private static let outcome: Int32 = libssh2_init(0)

    static func start() throws {
        guard outcome == 0 else { throw TransportFailure.handshakeFailed(code: outcome) }
    }
}

public enum LibSSH2 {
    public struct Failure: Error, Sendable, Equatable {
        public let code: Int32

        public init(code: Int32) {
            self.code = code
        }
    }

    public static var version: String {
        guard let raw = libssh2_version(0) else { return "" }
        return String(cString: raw)
    }

    public static func withLibrary<T>(_ body: () throws -> T) throws -> T {
        do {
            try LibSSH2Library.start()
        } catch let failure as TransportFailure {
            throw Failure(code: failure.code ?? -1)
        }
        return try body()
    }
}
