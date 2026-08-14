import AnySSHCore

public actor ConnectionCredentials {
    public typealias Resolve = @Sendable () async throws -> AuthCredential

    private let resolve: Resolve
    private var resolved: AuthCredential?
    private var inFlight: Task<AuthCredential, any Error>?
    private var handedOut = 0

    public init(resolve: @escaping Resolve) {
        self.resolve = resolve
    }

    public init(_ credential: AuthCredential) {
        resolve = { credential }
    }

    public private(set) var resolutions = 0

    public var issued: Int {
        handedOut
    }

    public func credential() async throws -> AuthCredential {
        if let resolved {
            handedOut += 1
            return resolved
        }
        if let inFlight {
            let value = try await inFlight.value
            handedOut += 1
            return value
        }
        let task = Task { [resolve] in try await resolve() }
        inFlight = task
        resolutions += 1
        do {
            let value = try await task.value
            resolved = value
            inFlight = nil
            handedOut += 1
            return value
        } catch {
            inFlight = nil
            throw error
        }
    }
}
