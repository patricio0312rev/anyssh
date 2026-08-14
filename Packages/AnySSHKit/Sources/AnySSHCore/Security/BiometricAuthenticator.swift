import Foundation

public enum BiometricOutcome: Hashable, Sendable {
    case authenticated
    case cancelled
    case unavailable
}

public protocol BiometricPresentation: Sendable {
    func apply(to query: inout [String: Any])

    func invalidate()
}

extension BiometricPresentation {
    public func invalidate() {}
}

public struct BiometricResult: Sendable {
    public let outcome: BiometricOutcome
    public let presentation: (any BiometricPresentation)?

    public init(_ outcome: BiometricOutcome, presentation: (any BiometricPresentation)? = nil) {
        self.outcome = outcome
        self.presentation = presentation
    }
}

public protocol BiometricAuthenticator: Sendable {
    func authenticate(reason: String) async -> BiometricResult
}
