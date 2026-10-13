import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    static let muxHopLimit = Duration.seconds(10)

    func swipeTarget(
        _ direction: SessionSwipeRing.Direction,
        skippingMux: Bool = false
    ) -> SessionSwipeRing.Target? {
        guard let activeSessionID else { return nil }
        let topology =
            skippingMux
            ? SessionMuxTopologyCache.Topology()
            : muxTopologyCache.topology(for: activeSessionID)
        let ring = SessionSwipeRing(
            muxSessions: topology.sessions,
            boundMuxSession: sessionMuxIDs[activeSessionID],
            boundGroups: topology.groups,
            focusedGroup: sessionMuxGroupIDs[activeSessionID],
            appSessionIDs: registry.ids,
            activeSessionID: activeSessionID
        )
        return ring.step(direction)
    }

    func hop(
        toMuxSession target: MuxSessionID,
        within limit: Duration = SessionWorkspaceModel.muxHopLimit,
        onSkip: @escaping @MainActor () -> Void = {}
    ) {
        hop(to: .session(target), within: limit, onSkip: onSkip)
    }

    func hop(
        toMuxGroup target: MuxGroupID,
        within limit: Duration = SessionWorkspaceModel.muxHopLimit,
        onSkip: @escaping @MainActor () -> Void = {}
    ) {
        guard let sessionID = activeSessionID, let bound = sessionMuxIDs[sessionID] else { return }
        hop(to: .group(target, of: bound), within: limit, onSkip: onSkip)
    }

    func primeMuxTopology() async {
        guard let sessionID = activeSessionID, let adapter = activeMultiplexerAdapter else {
            return
        }
        await refreshMuxTopology(for: sessionID, using: adapter)
    }

    func scheduleMuxTopologyRefresh(for sessionID: SessionID) {
        guard let adapter = sessionAdapters[sessionID] ?? multiplexerAdapter else { return }
        Task { [weak self] in
            await self?.refreshMuxTopology(for: sessionID, using: adapter)
        }
    }

    func refreshMuxTopology(for sessionID: SessionID, using adapter: any MultiplexerAdapter) async {
        let request = muxTopologyCache.beginRefresh(for: sessionID)
        let topology: SessionMuxTopologyCache.Topology
        do {
            let sessions = try await adapter.listSessions()
            let groups = try await boundGroups(for: sessionID, in: sessions, using: adapter)
            topology = SessionMuxTopologyCache.Topology(sessions: sessions, groups: groups)
        } catch {
            return
        }
        muxTopologyCache.store(topology, for: sessionID, request: request)
    }

    private func boundGroups(
        for sessionID: SessionID,
        in sessions: [MuxSession],
        using adapter: any MultiplexerAdapter
    ) async throws -> [MuxGroup] {
        guard let bound = sessionMuxIDs[sessionID], sessions.contains(where: { $0.id == bound })
        else { return [] }
        return try await adapter.snapshot(bound).groups
    }

    private func hopContext() -> HopContext? {
        guard !isHoppingMuxSession,
            let sessionID = activeSessionID,
            let adapter = activeMultiplexerAdapter,
            let connection = connections[sessionID]
        else { return nil }
        return HopContext(
            sessionID: sessionID,
            adapter: adapter,
            navigator: MuxNavigator(
                adapter: adapter,
                writer: connection,
                probe: attachmentProbe(for: sessionID)
            )
        )
    }

    private func hop(
        to destination: MuxHopDestination,
        within limit: Duration,
        onSkip: @escaping @MainActor () -> Void
    ) {
        guard let context = hopContext() else { return }
        isHoppingMuxSession = true
        Task { [weak self] in
            await self?.hop(to: destination, in: context, within: limit, onSkip: onSkip)
        }
    }

    private func hop(
        to destination: MuxHopDestination,
        in context: HopContext,
        within limit: Duration,
        onSkip: @MainActor () -> Void
    ) async {
        let outcome = await attempt(destination, with: context.navigator, within: limit)
        let skipped = outcome.map { announce($0, for: destination, of: context.sessionID) } ?? false
        await settle(skipped: skipped, in: context, onSkip: onSkip)
    }

    private func attempt(
        _ destination: MuxHopDestination,
        with navigator: MuxNavigator,
        within limit: Duration
    ) async -> MuxJumpOutcome? {
        do {
            return try await MuxHopDeadline.run(within: limit) {
                try await destination.jump(with: navigator)
            }
        } catch is MuxHopDeadline.Expired {
            return .skipped(destination.session, .timedOut)
        } catch {
            announceFailure(error)
            return nil
        }
    }

    private func settle(
        skipped: Bool,
        in context: HopContext,
        onSkip: @MainActor () -> Void
    ) async {
        isHoppingMuxSession = false
        if skipped { onSkip() }
        await refreshMuxTopology(for: context.sessionID, using: context.adapter)
        guard !skipped else { return }
        await detectAgent(for: context.sessionID)
    }

    private func announce(
        _ outcome: MuxJumpOutcome,
        for destination: MuxHopDestination,
        of sessionID: SessionID
    ) -> Bool {
        if let reason = outcome.skipReason {
            announceSkip(reason)
            return true
        }
        switch destination {
        case .session(let target):
            rememberMuxSession(target, for: sessionID)
            announceSwitch(
                name(of: target, in: sessionID).map(MuxNavigationCopy.switched(to:))
                    ?? MuxNavigationCopy.switchedSession
            )
        case .group(let target, _):
            rememberMuxGroup(target, for: sessionID)
            announceSwitch(
                title(of: target, in: sessionID).map(MuxNavigationCopy.switched(to:))
                    ?? MuxNavigationCopy.switchedTab
            )
        }
        return false
    }

    private func announceFailure(_ error: any Error) {
        statusToasts?.present(state: (error as? ErrorState) ?? .mux(.attachTargetVanished))
    }

    private func announceSwitch(_ title: String) {
        statusToasts?.present(
            severity: .success,
            title: title,
            accessibilityIdentifier: UIIdentifier.Session.muxSwitchToast
        )
    }

    private func announceSkip(_ reason: MuxSkipReason) {
        let copy = MuxNavigationCopy.skipped(reason)
        statusToasts?.present(severity: .attention, title: copy.title, body: copy.body)
    }

    private func name(of target: MuxSessionID, in sessionID: SessionID) -> String? {
        muxTopologyCache.sessions(for: sessionID).first { $0.id == target }?.name
    }

    private func title(of group: MuxGroupID, in sessionID: SessionID) -> String? {
        let title = muxTopologyCache.groups(for: sessionID).first { $0.id == group }?.title
        return title == group.rawValue ? nil : title
    }
}

private struct HopContext: Sendable {
    let sessionID: SessionID
    let adapter: any MultiplexerAdapter
    let navigator: MuxNavigator
}
