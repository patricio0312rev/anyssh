import Foundation
import Synchronization
import Testing

@testable import AnySSHCore

final class ChannelLedger: Sendable {
    private struct State {
        var openIDs: Set<Int> = []
        var issued = 0
        var closes = 0
    }

    private let state = Mutex(State())

    var openCount: Int { state.withLock { $0.openIDs.count } }
    var closeCount: Int { state.withLock { $0.closes } }

    func open() -> Int {
        state.withLock { state in
            state.issued += 1
            state.openIDs.insert(state.issued)
            return state.issued
        }
    }

    func close(_ channel: Int) {
        state.withLock { state in
            guard state.openIDs.remove(channel) != nil else { return }
            state.closes += 1
        }
    }
}

struct ContractRunner: RemoteCommandRunner {
    let ledger: ChannelLedger

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let channel = ledger.open()
        do {
            try await withTaskCancellationHandler {
                try await Task.sleep(for: .seconds(30))
            } onCancel: {
                ledger.close(channel)
            }
        } catch {
            throw ErrorState.transport(.cancelledBySwitch)
        }
        ledger.close(channel)
        return BatchResponse(sections: [])
    }
}

struct LeakingRunner: RemoteCommandRunner {
    let ledger: ChannelLedger

    func run(_ batch: RemoteBatch) async throws -> BatchResponse {
        let channel = ledger.open()
        try await Task.sleep(for: .seconds(30))
        ledger.close(channel)
        return BatchResponse(sections: [])
    }
}
