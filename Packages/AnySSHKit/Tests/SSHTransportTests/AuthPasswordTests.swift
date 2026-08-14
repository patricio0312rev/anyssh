import AnySSHCore
import Foundation
import Testing

@testable import SSHTransport

@Suite(.enabled(if: AuthEnvironment.isAvailable))
struct AuthPasswordTests {
    private let user = "pwuser"

    @Test func authenticatesWithTheRightPassword() async throws {
        let credentials = try #require(AuthEnvironment.credentials)
        let session = try await AuthSupport.opened()
        try await session.authenticate(as: user, with: .password(credentials.password))
        #expect(await session.isAuthenticated)
        await session.close()
    }

    @Test func reportsAWrongPasswordAsARejection() async throws {
        let credentials = try #require(AuthEnvironment.credentials)
        let session = try await AuthSupport.opened()
        let failure = await AuthSupport.failure(of: {
            try await session.authenticate(as: user, with: .password(credentials.wrongPassword))
        })

        #expect(failure?.stateID == "auth.passwordRejected")
        #expect(await session.isAuthenticated == false)
        await session.close()
    }

    @Test func doesNotRetryInsideOneCall() async throws {
        let credentials = try #require(AuthEnvironment.credentials)
        let session = try await AuthSupport.opened()
        var rejections = 0
        for _ in 0..<3 {
            let failure = await AuthSupport.failure(of: {
                try await session.authenticate(as: user, with: .password(credentials.wrongPassword))
            })
            if failure?.stateID == "auth.passwordRejected" { rejections += 1 }
        }

        #expect(rejections == 3)
        await session.close()

        let fresh = try await AuthSupport.opened()
        try await fresh.authenticate(as: user, with: .password(credentials.password))
        #expect(await fresh.isAuthenticated)
        await fresh.close()
    }

    @Test func offersOnlyPasswordForThePasswordAccount() async throws {
        let session = try await AuthSupport.opened()
        #expect(try await session.offeredMethods(for: user) == ["password"])
        await session.close()
    }
}
