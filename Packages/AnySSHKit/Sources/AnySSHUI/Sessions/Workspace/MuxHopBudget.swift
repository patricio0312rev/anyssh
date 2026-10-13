struct MuxHopBudget: Sendable {
    let limit: Duration
    let grace: Duration

    static let standard = MuxHopBudget(limit: .seconds(10), grace: .seconds(2))
}
