import AnySSHCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct AccessoryKeyButton: View {
    let key: AccessoryLayout.Key
    let model: AccessoryBarModel
    let draggedID: Binding<String?>
    let isReordering: Bool

    @State private var isPressed = false

    var body: some View {
        Text(model.title(for: key))
            .font(Theme.code(size: AccessoryBarMetrics.keyFontSize))
            .foregroundStyle(isModifierActive ? Theme.surface.base : Theme.text.primary)
            .frame(
                minWidth: Theme.Buttons.iconHitTarget,
                minHeight: AccessoryBarMetrics.keyHeight
            )
            .padding(.horizontal, Theme.Space.step1)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Space.controlRadius))
            .contentShape(RoundedRectangle(cornerRadius: Theme.Space.controlRadius))
            .accessibilityElement()
            .accessibilityLabel(key.label)
            .accessibilityIdentifier(key.id)
            .accessibilityAddTraits(.isButton)
            .onTapGesture(count: 2) { activate(key.doubleTap) }
            .onTapGesture(count: 1) { activate(key.tap) }
            .onLongPressGesture(
                minimumDuration: 0.45,
                maximumDistance: 32,
                pressing: pressing,
                perform: longPress
            )
            .overlay(alignment: .top) {
                if isReordering {
                    Image(systemName: "line.3.horizontal")
                        .font(Theme.Text.caption)
                        .foregroundStyle(Theme.accent)
                        .offset(y: -Theme.Space.step1)
                        .accessibilityHidden(true)
                }
            }
            .if(isReordering) { view in
                view.onDrag {
                    draggedID.wrappedValue = key.id
                    return NSItemProvider(object: NSString(string: key.id))
                }
            }
            .contextMenu {
                Button("Remove", role: .destructive) { model.remove(id: key.id) }
            }
    }

    private var fill: some ShapeStyle {
        if isModifierActive { return AnyShapeStyle(Theme.accent) }
        if isPressed { return AnyShapeStyle(Theme.surface.overlay) }
        return AnyShapeStyle(Color.clear)
    }

    private var isModifierActive: Bool {
        guard case .modifier(let modifier) = AccessoryAction(key.tap) else { return false }
        return model.input.latch[modifier] != .off
    }

    private func activate(_ binding: AccessoryLayout.Binding) {
        AccessoryFeedback.tap()
        Task { await model.activate(binding) }
    }

    private func pressing(_ isPressing: Bool) {
        isPressed = isPressing
        if !isPressing { model.stopRepeating() }
    }

    private func longPress() {
        activate(key.longPress)
        if key.repeats { model.startRepeating(key.longPress) }
    }
}

struct AccessoryDropDelegate: DropDelegate {
    let targetID: String
    let model: AccessoryBarModel
    let draggedID: Binding<String?>

    func dropEntered(info: DropInfo) {
        guard let source = draggedID.wrappedValue, source != targetID else { return }
        model.move(id: source, before: targetID)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedID.wrappedValue = nil
        return true
    }
}
