import AnySSHCore

public actor ResizeCoordinator {
    public typealias Apply = @Sendable (TerminalSize) async -> Void
    public typealias Wait = @Sendable (Duration) async -> Void
    public typealias Now = @Sendable () -> ContinuousClock.Instant

    private let apply: Apply
    private let wait: Wait
    private let now: Now

    private var debounce: ResizeDebounce
    private var timer: Task<Void, Never>?
    private var lastRecorded: ContinuousClock.Instant?

    public private(set) var deliveredCount = 0
    public private(set) var waitCount = 0

    public init(
        window: Duration = ResizeDebounce.window,
        started: TerminalSize? = nil,
        now: @escaping Now = { .now },
        wait: @escaping Wait = { try? await Task.sleep(for: $0) },
        apply: @escaping Apply
    ) {
        debounce = ResizeDebounce(window: window, delivered: started)
        self.now = now
        self.wait = wait
        self.apply = apply
    }

    public static func driving(
        _ transport: any TerminalTransport,
        window: Duration = ResizeDebounce.window,
        started: TerminalSize? = nil
    ) -> ResizeCoordinator {
        ResizeCoordinator(window: window, started: started) { size in
            try? await transport.resize(to: size)
        }
    }

    public nonisolated func sizeChanged(to size: TerminalSize) {
        let instant = now()
        Task { await record(size, at: instant) }
    }

    public func record(_ size: TerminalSize) {
        record(size, at: now())
    }

    public func record(_ size: TerminalSize, at instant: ContinuousClock.Instant) {
        guard instant >= lastRecorded ?? instant else { return }
        lastRecorded = instant
        guard case .scheduled = debounce.record(size, at: instant) else { return }
        guard timer == nil else { return }
        timer = Task { await releaseWhenQuiet() }
    }

    public func flush() async {
        timer?.cancel()
        timer = nil
        guard let due = debounce.deadline, let size = debounce.fire(at: due) else { return }
        await deliver(size)
    }

    private func releaseWhenQuiet() async {
        while let due = debounce.deadline {
            guard !Task.isCancelled else { return }
            let remaining = now().duration(to: due)
            if remaining > .zero {
                waitCount += 1
                await wait(remaining)
                continue
            }
            guard let size = debounce.fire(at: now()) else { continue }
            await deliver(size)
        }
        timer = nil
    }

    private func deliver(_ size: TerminalSize) async {
        await apply(size)
        deliveredCount += 1
    }
}
