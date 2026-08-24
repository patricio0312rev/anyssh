@MainActor
final class SkipRecorder {
    private(set) var count = 0

    func record() {
        count += 1
    }
}
