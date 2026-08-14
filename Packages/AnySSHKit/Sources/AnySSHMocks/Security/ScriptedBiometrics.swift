import AnySSHCore
import Foundation

public struct ScriptedBiometrics: BiometricAuthenticator {
    public let outcome: BiometricOutcome

    public init(_ outcome: BiometricOutcome = .authenticated) {
        self.outcome = outcome
    }

    public func authenticate(reason: String) async -> BiometricResult {
        BiometricResult(outcome)
    }
}
