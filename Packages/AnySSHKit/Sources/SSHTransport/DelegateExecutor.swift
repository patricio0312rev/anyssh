import Foundation

final class DelegateExecutor: TaskExecutor, @unchecked Sendable {
    static let shared = DelegateExecutor()

    static let threadPrefix = "anyssh.delegate."

    static var isCurrent: Bool {
        var buffer = [CChar](repeating: 0, count: 64)
        guard pthread_getname_np(pthread_self(), &buffer, buffer.count) == 0 else { return false }
        return String(cString: buffer).hasPrefix(threadPrefix)
    }

    private let mutex = NSCondition()
    private var pending = [UnownedJob]()

    private init(width: Int = max(4, ProcessInfo.processInfo.activeProcessorCount / 4)) {
        for index in 0..<width { start(index) }
    }

    func enqueue(_ job: consuming ExecutorJob) {
        let job = UnownedJob(job)
        mutex.lock()
        pending.append(job)
        mutex.signal()
        mutex.unlock()
    }

    private func start(_ index: Int) {
        let thread = Thread { [self] in
            Thread.current.name = "\(Self.threadPrefix)\(index)"
            while true {
                mutex.lock()
                while pending.isEmpty { mutex.wait() }
                let job = pending.removeFirst()
                mutex.unlock()
                job.runSynchronously(on: asUnownedTaskExecutor())
            }
        }
        thread.name = "\(Self.threadPrefix)\(index)"
        thread.stackSize = 512 * 1024
        thread.start()
    }
}
