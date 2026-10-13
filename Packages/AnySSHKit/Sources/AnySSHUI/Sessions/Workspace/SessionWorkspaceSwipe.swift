import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    static let muxHopLimit = Duration.seconds(10)

    func swipeTarget(
        _ direction: SessionSwipeRing.Direction,
        skippingMux: Bool = false
    ) -> SessionSwipeRing.Target? {
        guard let activeSessionID else { return nil }
        return swipeTarget(direction, from: activeSessionID, skippingMux: skippingMux)
    }

    func hop(
        toMuxSession target: MuxSessionID,
        within limit: Duration = SessionWorkspaceModel.muxHopLimit,
        onSkip: @escaping @MainActor () -> Void = {}
    ) {
        hop(.session(target), within: limit, onSkip: onSkip)
    }

    func hop(
        tabToward direction: SessionSwipeRing.Direction,
        within limit: Duration = SessionWorkspaceModel.muxHopLimit,
        onSkip: @escaping @MainActor () -> Void = {}
    ) {
        hop(.tab(direction), within: limit, onSkip: onSkip)
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
        guard registry[sessionID] != nil else { return }
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

    private func swipeTarget(
        _ direction: SessionSwipeRing.Direction,
        from sessionID: SessionID,
        skippingMux: Bool = false
    ) -> SessionSwipeRing.Target? {
        let topology =
            skippingMux
            ? SessionMuxTopologyCache.Topology()
            : muxTopologyCache.topology(for: sessionID)
        let ring = SessionSwipeRing(
            muxSessions: topology.sessions,
            boundMuxSession: sessionMuxIDs[sessionID],
            boundGroups: topology.groups,
            focusedGroup: sessionMuxGroupIDs[sessionID],
            appSessionIDs: registry.ids,
            activeSessionID: sessionID
        )
        return ring.step(direction)
    }

    private func hop(
        _ plan: MuxHopPlan,
        within limit: Duration,
        onSkip: @escaping @MainActor () -> Void
    ) {
        guard let context = hopContext() else { return }
        isHoppingMuxSession = true
        Task { [weak self] in
            await self?.hop(plan, in: context, within: limit, onSkip: onSkip)
        }
    }

    private func hop(
        _ plan: MuxHopPlan,
        in context: HopContext,
        within limit: Duration,
        onSkip: @MainActor () -> Void
    ) async {
        let skipped = await land(plan, in: context, within: limit)
        await settle(skipped: skipped, in: context, within: limit, onSkip: onSkip)
    }

    private func land(_ plan: MuxHopPlan, in context: HopContext, within limit: Duration) async -> Bool {
        do {
            let landing = try await MuxHopDeadline.run(within: limit) { [weak self] in
                try await self?.jump(plan, in: context)
            }
            guard let landing else { return true }
            return announce(landing.outcome, for: landing.destination, of: context.sessionID)
        } catch is MuxHopDeadline.Expired {
            announceSkip(.timedOut)
            return true
        } catch {
            announceFailure(error)
            return false
        }
    }

    private func jump(
        _ plan: MuxHopPlan,
        in context: HopContext
    ) async throws -> (destination: MuxHopDestination, outcome: MuxJumpOutcome)? {
        guard let destination = await destination(for: plan, in: context) else { return nil }
        return (destination, try await destination.jump(with: context.navigator))
    }

    private func destination(for plan: MuxHopPlan, in context: HopContext) async -> MuxHopDestination? {
        switch plan {
        case .session(let target):
            return .session(target)
        case .tab(let direction):
            await refreshMuxTopology(for: context.sessionID, using: context.adapter)
            switch swipeTarget(direction, from: context.sessionID) {
            case .muxGroup(let group):
                return sessionMuxIDs[context.sessionID].map { MuxHopDestination.group(group, of: $0) }
            case .muxSession(let session):
                return .session(session)
            case .appSession, nil:
                return nil
            }
        }
    }

    private func settle(
        skipped: Bool,
        in context: HopContext,
        within limit: Duration,
        onSkip: @MainActor () -> Void
    ) async {
        guard !skipped else {
            isHoppingMuxSession = false
            onSkip()
            await refreshMuxTopology(for: context.sessionID, using: context.adapter)
            return
        }
        await refreshAfterHop(in: context, within: limit)
        isHoppingMuxSession = false
        await detectAgent(for: context.sessionID)
    }

    private func refreshAfterHop(in context: HopContext, within limit: Duration) async {
        do {
            try await MuxHopDeadline.run(within: limit) { [weak self] in
                await self?.refreshMuxTopology(for: context.sessionID, using: context.adapter)
            }
        } catch {
            return
        }
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
