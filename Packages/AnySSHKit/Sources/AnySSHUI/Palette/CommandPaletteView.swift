import SwiftUI

public struct CommandPaletteView: View {
    @State private var model: CommandPaletteModel
    @FocusState private var isSearchFocused: Bool

    private let onActivate: (String) -> Void
    private let onDismiss: () -> Void

    public init(
        entries: [PaletteEntry],
        initialQuery: String = "",
        onActivate: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _model = State(initialValue: CommandPaletteModel(entries: entries, query: initialQuery))
        self.onActivate = onActivate
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            search
            Rectangle()
                .fill(Theme.separator)
                .frame(height: 1)
            results
        }
        .background { Theme.surface.base.ignoresSafeArea() }
        .keyTraversal(
            onMoveUp: { model.moveUp() },
            onMoveDown: { model.moveDown() },
            onActivate: activateSelected,
            onDismiss: onDismiss
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(CommandPaletteIdentifier.surface)
    }

    private var search: some View {
        HStack(spacing: Theme.Space.step3) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.text.secondary)
            TextField("Filter commands", text: queryBinding)
                #if canImport(UIKit)
            .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
                .foregroundStyle(Theme.text.primary)
                .focused($isSearchFocused)
                .defaultFocus($isSearchFocused, true)
                .onSubmit(activateSelected)
                .accessibilityIdentifier(CommandPaletteIdentifier.search)
            CloseButton(accessibilityIdentifier: CommandPaletteIdentifier.close, action: onDismiss)
        }
        .padding(.leading, Theme.Space.screenMargin)
        .padding(.trailing, Theme.Space.step2)
        .padding(.vertical, Theme.Space.step2)
        .background { Theme.surface.raised.ignoresSafeArea() }
        .onAppear { isSearchFocused = true }
    }

    private var queryBinding: Binding<String> {
        Binding(
            get: { model.query },
            set: { model.setQuery($0) }
        )
    }

    @ViewBuilder
    private var results: some View {
        if model.matches.isEmpty {
            empty
        } else {
            ScrollView {
                LazyVStack(spacing: Theme.Space.rowGap) {
                    ForEach(model.matches) { entry in
                        CommandPaletteRow(
                            entry: entry,
                            isSelected: entry.id == model.selected?.id
                        )
                        .onTapGesture { activate(entry) }
                    }
                }
                .padding(Theme.Space.screenMargin)
            }
            .accessibilityIdentifier(CommandPaletteIdentifier.list)
        }
    }

    private var empty: some View {
        Text("No matching commands")
            .font(Theme.Text.body)
            .foregroundStyle(Theme.text.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(CommandPaletteIdentifier.empty)
    }

    private func activate(_ entry: PaletteEntry) {
        guard entry.isEnabled else { return }
        onActivate(entry.id)
    }

    private func activateSelected() {
        guard let selected = model.selected else { return }
        activate(selected)
    }
}
