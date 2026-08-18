import AnySSHCore
import Foundation
import SwiftUI
import TerminalEmulator
import UniformTypeIdentifiers

extension AccessoryBar {
    public var body: some View {
        HStack(spacing: Theme.Space.step1) {
            if showsKeyStrip { keyStrip }
            HStack(spacing: 0) {
                if !model.input.preview.isEmpty {
                    Text(model.input.preview)
                        .font(Theme.code(size: AccessoryBarMetrics.keyFontSize).weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.preview)
                }
                if let onImportFile {
                    IconButton(
                        systemImage: "doc.badge.plus",
                        label: "Import file",
                        surface: .toolbar,
                        accessibilityIdentifier: FileImportIdentifier.open
                    ) {
                        AccessoryFeedback.tap()
                        onImportFile()
                    }
                    .foregroundStyle(Theme.text.secondary)
                    .modifier(AccessoryControlSize())
                }
                if let onDictate {
                    IconButton(
                        systemImage: isDictating ? "mic.fill" : "mic",
                        label: isDictating ? "Stop dictating" : "Dictate",
                        surface: .toolbar,
                        accessibilityIdentifier: DictationIdentifier.open
                    ) {
                        AccessoryFeedback.tap()
                        onDictate()
                    }
                    .foregroundStyle(isDictating ? Theme.accent : Theme.text.secondary)
                    .modifier(AccessoryControlSize())
                    .accessibilityValue(isDictating ? "listening" : "off")
                }
                Menu {
                    menuContent
                } label: {
                    Image(systemName: reorderMode ? "arrow.up.arrow.down.circle.fill" : "ellipsis.circle")
                        .font(Theme.Text.body)
                        .foregroundStyle(Theme.text.secondary)
                        .modifier(AccessoryControlSize())
                }
                .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.menu)
            }
            .fixedSize()
        }
        .padding(.trailing, Theme.Space.step2)
        .padding(.vertical, Theme.Space.step1)
        .glassEffect(.regular, in: .rect)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(reorderMode ? Theme.accent : Theme.separator)
                .frame(height: AccessoryBarMetrics.hairline)
        }
        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.bar)
    }

    @ViewBuilder
    private var menuContent: some View {
        if let onOpenChanges {
            Button("Changes", systemImage: "arrow.triangle.branch", action: onOpenChanges)
                .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.changes)
        }
        if let onOpenFiles {
            Button("Files", systemImage: "folder", action: onOpenFiles)
                .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.files)
        }
        if let onOpenMultiplexer {
            Button(
                "Multiplexer Panels", systemImage: "rectangle.split.3x1",
                action: onOpenMultiplexer
            )
            .accessibilityIdentifier(MultiplexerIdentifier.open)
        }
        if let onOpenJumpTo {
            Button("Jump to Session", systemImage: "list.bullet.indent", action: onOpenJumpTo)
                .accessibilityIdentifier(JumpToIdentifier.open)
        }
        if let onOpenSnippets {
            Button(
                "Snippets", systemImage: "chevron.left.forwardslash.chevron.right",
                action: onOpenSnippets
            )
            .accessibilityIdentifier(SnippetIdentifier.sheet)
        }
        Divider()
        Button(reorderMode ? "Finish Reordering" : "Reorder Keys") {
            reorderMode.toggle()
        }
        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.reorder)
        Button("Add Enter") {
            model.add(Self.enterKey)
        }
        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.add)
        Button("Add Prefix") {
            model.add(AccessoryLayout.prefixKey)
        }
        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.addPrefix)
        Button("Reset to Defaults", role: .destructive) {
            model.reset()
        }
        .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.reset)
    }

    private var keyStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Space.step2) {
                    ForEach(model.layout.keys) { key in
                        AccessoryKeyButton(
                            key: key,
                            model: model,
                            draggedID: $draggedID,
                            isReordering: reorderMode
                        )
                        .onDrop(
                            of: [UTType.text],
                            delegate: AccessoryDropDelegate(
                                targetID: key.id,
                                model: model,
                                draggedID: $draggedID
                            )
                        )
                    }
                }
                .padding(.leading, Theme.Space.step2)
            }
            .onAppear {
                guard let scrollToID else { return }
                proxy.scrollTo(scrollToID, anchor: .leading)
            }
            .accessibilityIdentifier(UIIdentifier.Terminal.Accessory.overflow)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }

    private static let enterKey = AccessoryLayout.Key(
        id: "terminal.accessory.key.enter",
        label: "Enter",
        tap: .key("enter")
    )
}

struct AccessoryControlSize: ViewModifier {
    func body(content: Content) -> some View {
        content.frame(
            minWidth: Theme.Buttons.iconHitTarget,
            minHeight: AccessoryBarMetrics.keyHeight
        )
    }
}
