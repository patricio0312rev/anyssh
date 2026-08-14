import Foundation
import LocalAuthentication
import Security

public struct LocalAuthenticationGate: BiometricAuthenticator {
    public init() {}

    public func authenticate(reason: String) async -> BiometricResult {
        let context = LAContext()
        var inspection: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &inspection) else {
            return BiometricResult(Self.outcome(for: inspection))
        }
        do {
            let control = try SecItemAttributes.accessControl()
            try await evaluate(control, on: context, reason: reason)
            return BiometricResult(
                .authenticated,
                presentation: LocalAuthenticationPresentation(context: context)
            )
        } catch {
            return BiometricResult(Self.outcome(for: error))
        }
    }

    private func evaluate(
        _ control: SecAccessControl,
        on context: LAContext,
        reason: String
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            context.evaluateAccessControl(
                control,
                operation: .useItem,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? LAError(.authenticationFailed))
                }
            }
        }
    }

    static func outcome(for error: (any Error)?) -> BiometricOutcome {
        guard let code = (error as? NSError).flatMap({ LAError.Code(rawValue: $0.code) }) else {
            return .unavailable
        }
        switch code {
        case .userCancel, .appCancel, .systemCancel, .authenticationFailed, .userFallback:
            return .cancelled
        default:
            return .unavailable
        }
    }
}

final class LocalAuthenticationPresentation: BiometricPresentation, @unchecked Sendable {
    private let context: LAContext

    init(context: LAContext) {
        self.context = context
        context.interactionNotAllowed = true
    }

    func apply(to query: inout [String: Any]) {
        query[kSecUseAuthenticationContext as String] = context
    }

    func invalidate() {
        context.invalidate()
    }
}
