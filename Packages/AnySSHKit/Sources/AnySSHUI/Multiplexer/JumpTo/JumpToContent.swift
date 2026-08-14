import AnySSHCore
import SwiftUI

struct JumpToContent: View {
    let model: JumpToModel
    let onJump: (JumpRow) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: JumpToMetrics.cardColumn), spacing: Theme.Space.step3)
    ]

    var body: some View {
        switch model.layout {
        case .list: list
        case .accordion: accordion
        case .grid: grid
        }
    }

    private var list: some View {
        List {
            ForEach(model.sessions) { session in
                Section {
                    ForEach(session.groups) { row in
                        JumpToRowView(
                            row: row,
                            isJumping: model.jumpingRowID == row.id,
                            onTap: { onJump(row) }
                        )
                        .catalogRowChrome(selected: row.isActive)
                    }
                } header: {
                    sectionHeader(session)
                }
            }
        }
        .catalogListSurface()
    }

    private var accordion: some View {
        List {
            ForEach(model.sessions) { session in
                Section {
                    if model.expandedSessionIDs.contains(session.id) {
                        ForEach(session.groups) { row in
                            JumpToRowView(
                                row: row,
                                isJumping: model.jumpingRowID == row.id,
                                onTap: { onJump(row) }
                            )
                            .catalogRowChrome()
                        }
                    }
                } header: {
                    disclosureHeader(session)
                }
            }
        }
        .catalogListSurface()
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Theme.Space.step3) {
                ForEach(model.sessions) { session in
                    card(session)
                }
            }
            .padding(Theme.Space.screenMargin)
        }
        .background { Theme.surface.base.ignoresSafeArea() }
    }

    private func sectionHeader(_ session: JumpSession) -> some View {
        SectionLabel(session.name)
            .accessibilityIdentifier(JumpToIdentifier.group(session.id.rawValue))
    }

    private func disclosureHeader(_ session: JumpSession) -> some View {
        Button {
            model.toggleExpanded(session.id)
        } label: {
            HStack(spacing: Theme.Space.step2) {
                Image(
                    systemName: model.expandedSessionIDs.contains(session.id)
                        ? "chevron.down"
                        : "chevron.right"
                )
                .font(Theme.Text.caption)
                .foregroundStyle(Theme.text.secondary)
                SectionLabel(session.name)
                Text("\(session.groups.count)")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.tertiary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(JumpToIdentifier.group(session.id.rawValue))
    }

    private func card(_ session: JumpSession) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: Theme.Space.step2) {
                PrimaryTitle(session.name)
                if session.groups.isEmpty {
                    Text("No windows")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.text.tertiary)
                } else {
                    ForEach(session.groups) { row in
                        chip(row)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(JumpToIdentifier.card(session.id.rawValue))
    }

    private func chip(_ row: JumpRow) -> some View {
        Button {
            onJump(row)
        } label: {
            HStack(spacing: Theme.Space.step2) {
                Text(row.title)
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 0)
                if model.jumpingRowID == row.id {
                    LoadingView(.inline)
                        .accessibilityIdentifier(JumpToIdentifier.jumping(row.id.rawValue))
                } else {
                    JumpToStatusDot(row: row)
                }
            }
            .padding(.horizontal, Theme.Space.step3)
            .frame(minHeight: Theme.Buttons.height)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface.overlay, in: Capsule())
            .overlay {
                if row.isActive { Capsule().strokeBorder(Theme.accent, lineWidth: 1.5) }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(JumpToIdentifier.chip(row.id.rawValue))
    }
}

enum JumpToMetrics {
    static let cardColumn: CGFloat = 160
}

extension JumpLayout {
    var label: String {
        switch self {
        case .list: "List"
        case .accordion: "Accordion"
        case .grid: "Grid"
        }
    }

    var identifier: String {
        switch self {
        case .list: JumpToIdentifier.layoutList
        case .accordion: JumpToIdentifier.layoutAccordion
        case .grid: JumpToIdentifier.layoutGrid
        }
    }
}
