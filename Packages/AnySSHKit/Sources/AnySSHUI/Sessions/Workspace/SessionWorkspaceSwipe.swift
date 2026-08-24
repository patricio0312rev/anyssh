import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
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

    func hop(toMuxSession target: MuxSessionID, onSkip: @escaping @MainActor () -> Void = {}) {
        guard let context = hopContext() else { return }
        isHoppingMuxSession = true
        Task { [weak self] in
            await self?.hop(toMuxSession: target, in: context, onSkip: onSkip)
        }
    }

    func hop(toMuxGroup target: MuxGroupID, onSkip: @escaping @MainActor () -> Void = {}) {
        guard let context = hopContext(), let bound = sessionMuxIDs[context.sessionID] else {
            return
        }
        isHoppingMuxSession = true
        Task { [weak self] in
            await self?.hop(toMuxGroup: target, of: bound, in: context, onSkip: onSkip)
        }
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
        let generation = muxTopologyCache.generation(for: sessionID)
        do {
            let sessions = try await adapter.listSessions()
            let groups = try await boundGroups(for: sessionID, in: sessions, using: adapter)
            muxTopologyCache.store(
                SessionMuxTopologyCache.Topology(sessions: sessions, groups: groups),
                for: sessionID,
                generation: generation
            )
        } catch {
            muxTopologyCache.clear(for: sessionID)
        }
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
        toMuxSession target: MuxSessionID,
        in context: HopContext,
        onSkip: @MainActor () -> Void
    ) async {
        var skipped = false
        do {
            let outcome = try await context.navigator.jump(toSession: target)
            skipped = announce(outcome, target: target, of: context.sessionID)
        } catch {
            announceFailure(error)
        }
        await settle(skipped: skipped, in: context, onSkip: onSkip)
    }

    private func hop(
        toMuxGroup target: MuxGroupID,
        of bound: MuxSessionID,
        in context: HopContext,
        onSkip: @MainActor () -> Void
    ) async {
        var skipped = false
        do {
            let outcome = try await context.navigator.jump(
                toGroup: MuxTarget(session: bound, group: target)
            )
            skipped = announce(outcome, group: target, of: context.sessionID)
        } catch {
            announceFailure(error)
        }
        await settle(skipped: skipped, in: context, onSkip: onSkip)
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
        target: MuxSessionID,
        of sessionID: SessionID
    ) -> Bool {
        switch outcome {
        case .attached, .focused:
            rememberMuxSession(target, for: sessionID)
            announceSwitch(
                name(of: target, in: sessionID).map(MuxNavigationCopy.switched(to:))
                    ?? MuxNavigationCopy.switchedSession
            )
            return false
        case .focusedElsewhere, .skipped:
            announceRefusal(in: sessionID)
            return true
        }
    }

    private func announce(
        _ outcome: MuxJumpOutcome,
        group target: MuxGroupID,
        of sessionID: SessionID
    ) -> Bool {
        switch outcome {
        case .attached, .focused:
            rememberMuxGroup(target, for: sessionID)
            announceSwitch(
                title(of: target, in: sessionID).map(MuxNavigationCopy.switched(to:))
                    ?? MuxNavigationCopy.switchedTab
            )
            return false
        case .focusedElsewhere, .skipped:
            announceRefusal(in: sessionID)
            return true
        }
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

    private func announceRefusal(in sessionID: SessionID) {
        statusToasts?.present(
            severity: .attention,
            title: MuxNavigationCopy.focused(in: boundName(in: sessionID)),
            body: MuxNavigationCopy.detachToSwitch
        )
    }

    private func name(of target: MuxSessionID, in sessionID: SessionID) -> String? {
        muxTopologyCache.sessions(for: sessionID).first { $0.id == target }?.name
    }

    private func title(of group: MuxGroupID, in sessionID: SessionID) -> String? {
        let title = muxTopologyCache.groups(for: sessionID).first { $0.id == group }?.title
        return title == group.rawValue ? nil : title
    }

    private func boundName(in sessionID: SessionID) -> String {
        guard let bound = sessionMuxIDs[sessionID],
            let name = name(of: bound, in: sessionID)
        else { return MuxNavigationCopy.currentSession }
        return name
    }
}

private struct HopContext: Sendable {
    let sessionID: SessionID
    let adapter: any MultiplexerAdapter
    let navigator: MuxNavigator
}
