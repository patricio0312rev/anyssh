import Testing

@testable import FileTransfer

@Suite struct TransferProgressTests {
    @Test func fractionIsZeroWhenNothingIsExpected() {
        #expect(TransferProgress(transferredBytes: 0, totalBytes: 0).fraction == 0)
    }

    @Test func completionRequiresAllBytes() {
        #expect(!TransferProgress(transferredBytes: 5, totalBytes: 10).isComplete)
        #expect(TransferProgress(transferredBytes: 10, totalBytes: 10).isComplete)
    }
}
