import AnySSHCore
import Foundation

extension SessionWorkspaceModel {
    public func beginSwitch(to id: SessionID) {
        if id == activeSessionID {
            clearPendingSwitch()
            return
        }
        markPendingSwitch(to: id)
    }

    public func completeSwitch() async {
        guard let target = takePendingTarget(), target != activeSessionID else {
            clearPendingSwitch()
            return
        }
        guard let outgoingID = activeSessionID,
            let outgoingSurface = surface(for: outgoingID),
            let incomingSurface = surface(for: target),
            let outgoingScope = scope(for: outgoingID)
        else {
            clearPendingSwitch()
            return
        }
        await outgoingScope.cancelAll(reason: .cancelledBySwitch)
        outgoingSurface.stopDraining()
        activate(target)
        registry.touch(target, at: Date.now)
        _ = await incomingSurface.pump.metrics
        incomingSurface.startDraining()
        attachPendingPane()
    }

    public func firstFramePresented(for id: SessionID) {
        endPendingSwitch(ifMatches: id)
    }

    public func select(_ id: SessionID, pane: MuxPaneID? = nil) {
        pendingPane = pane
        guard registry[id] != nil, surface(for: id) != nil else {
            pendingPane = nil
            return
        }
        if id == activeSessionID {
            attachPendingPane()
            return
        }
        let canSwitch =
            activeSessionID != nil
            && activeSessionID.flatMap { scope(for: $0) } != nil
        if canSwitch {
            beginSwitch(to: id)
            Task { await completeSwitch() }
        } else {
            activate(id)
            registry.touch(id, at: Date.now)
            store.surface(for: id)?.startDraining()
            attachPendingPane()
        }
    }
}
