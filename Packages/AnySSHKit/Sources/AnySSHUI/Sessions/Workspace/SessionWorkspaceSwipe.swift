import AnySSHCore
import Sessions

extension SessionWorkspaceModel {
    func swipeTarget(
        _ direction: SessionSwipeRing.Direction,
        skippingMux: Bool = false
    ) -> SessionSwipeRing.Target? {
        guard let activeSessionID else { return nil }
        let ring = SessionSwipeRing(
            muxSessions: skippingMux ? [] : muxSessionCache.sessions(for: activeSessionID),
            boundMuxSession: sessionMuxIDs[activeSessionID],
            appSessionIDs: registry.ids,
            activeSessionID: activeSessionID
        )
        return ring.step(direction)
    }

    func hop(toMuxSession target: MuxSessionID, onSkip: @escaping @MainActor () -> Void = {}) {
        guard !isHoppingMuxSession,
            let sessionID = activeSessionID,
            let adapter = activeMultiplexerAdapter,
            let connection = connections[sessionID]
        else { return }
        isHoppingMuxSession = true
        let navigator = MuxNavigator(
            adapter: adapter,
            writer: connection,
            probe: attachmentProbe(for: sessionID)
        )
        Task { [weak self] in
            await self?.hop(
                to: target,
                of: sessionID,
                using: adapter,
                through: navigator,
                onSkip: onSkip
            )
        }
    }

    func primeMuxSessions() async {
        guard let sessionID = activeSessionID, let adapter = activeMultiplexerAdapter else {
            return
        }
        await refreshMuxSessions(for: sessionID, using: adapter)
    }

    func refreshMuxSessions(for sessionID: SessionID, using adapter: any MultiplexerAdapter) async {
        let generation = muxSessionCache.generation(for: sessionID)
        do {
            let sessions = try await adapter.listSessions()
            muxSessionCache.store(sessions, for: sessionID, generation: generation)
        } catch {
            muxSessionCache.clear(for: sessionID)
        }
    }

    func cacheMuxSessions(_ sessions: [MuxSession], for sessionID: SessionID) {
        muxSessionCache.store(
            sessions,
            for: sessionID,
            generation: muxSessionCache.generation(for: sessionID)
        )
    }

    private func hop(
        to target: MuxSessionID,
        of sessionID: SessionID,
        using adapter: any MultiplexerAdapter,
        through navigator: MuxNavigator,
        onSkip: @MainActor () -> Void
    ) async {
        var skipped = false
        do {
            let outcome = try await navigator.jump(toSession: target)
            skipped = announce(outcome, target: target, of: sessionID)
        } catch {
            statusToasts?.present(state: (error as? ErrorState) ?? .mux(.attachTargetVanished))
        }
        isHoppingMuxSession = false
        if skipped { onSkip() }
        await refreshMuxSessions(for: sessionID, using: adapter)
    }

    private func announce(
        _ outcome: MuxJumpOutcome,
        target: MuxSessionID,
        of sessionID: SessionID
    ) -> Bool {
        switch outcome {
        case .attached, .focused:
            rememberMuxSession(target, for: sessionID)
            statusToasts?.present(
                severity: .success,
                title: MuxNavigationCopy.switched(to: name(of: target, in: sessionID)),
                accessibilityIdentifier: UIIdentifier.Session.muxSwitchToast
            )
            return false
        case .focusedElsewhere, .skipped:
            statusToasts?.present(
                severity: .attention,
                title: MuxNavigationCopy.focused(in: boundName(in: sessionID)),
                body: MuxNavigationCopy.detachToSwitch
            )
            return true
        }
    }

    private func name(of target: MuxSessionID, in sessionID: SessionID) -> String {
        muxSessionCache.sessions(for: sessionID).first { $0.id == target }?.name ?? target.rawValue
    }

    private func boundName(in sessionID: SessionID) -> String {
        guard let bound = sessionMuxIDs[sessionID] else { return MuxNavigationCopy.currentSession }
        return name(of: bound, in: sessionID)
    }
}
