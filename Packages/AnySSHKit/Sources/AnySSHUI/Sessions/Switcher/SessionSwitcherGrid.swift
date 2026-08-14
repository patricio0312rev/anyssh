import AnySSHCore
import SwiftUI

extension SessionSwitcherView {
    var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.Space.step3) {
                ForEach(model.registry.sessions) { record in
                    Button {
                        select(record.id)
                        onSwitch(record.id)
                    } label: {
                        SurfaceCard(isSelected: record.id == selectedID) {
                            row(record, style: .grid)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Space.screenMargin)
        }
    }

    var list: some View {
        List {
            ForEach(model.registry.sessions) { record in
                Button {
                    select(record.id)
                    onSwitch(record.id)
                } label: {
                    row(record, style: .list)
                }
                .buttonStyle(.plain)
                .catalogRowChrome(selected: record.id == selectedID)
                .swipeActions(edge: .trailing) {
                    CatalogSwipe.destructive(
                        title: "Close",
                        systemImage: "xmark",
                        accessibilityIdentifier: SessionSwitcherIdentifier.closeRow(
                            record.id.rawValue
                        )
                    ) {
                        Task { await model.close(record.id) }
                    }
                }
            }
        }
        .catalogListSurface()
    }

    private func row(_ record: SessionRecord, style: SessionSwitcherRow.Style) -> some View {
        SessionSwitcherRow(
            record: record,
            hostAddress: model.hostAddress(for: record.id),
            remoteName: model.remoteName(for: record.id),
            agentKind: model.agentKind(for: record.id),
            uptime: model.uptime(for: record.id),
            isActive: record.id == model.activeSessionID,
            style: style
        )
    }

    private var selectedID: SessionID? {
        let sessions = model.registry.sessions
        guard sessions.indices.contains(selection) else { return nil }
        return sessions[selection].id
    }

    func moveSelection(by delta: Int) {
        let count = model.registry.sessions.count
        guard count > 0 else { return }
        selection = (selection + delta + count) % count
    }

    func activateSelection() {
        guard let id = selectedID else { return }
        onSwitch(id)
    }

    private func select(_ id: SessionID) {
        if let index = model.registry.index(of: id) { selection = index }
    }
}
