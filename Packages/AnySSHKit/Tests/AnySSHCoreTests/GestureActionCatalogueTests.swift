import Testing

@testable import AnySSHCore

@Suite struct GestureActionCatalogueTests {
    @Test func everyDefaultBindingHasAName() {
        for (slot, binding) in GestureLayout.defaults.bindings {
            let title = GestureActionCatalogue.title(of: binding)
            #expect(!title.contains("."), "\(slot) shows the identifier \(title)")
            #expect(!title.contains("_"), "\(slot) shows the identifier \(title)")
        }
    }

    @Test func anUnboundSlotSaysSo() {
        #expect(GestureActionCatalogue.title(of: nil) == "Unbound")
    }

    @Test func anUnknownBindingShowsItself() {
        let binding = GestureLayout.Binding(kind: .appCommand, value: "view.blame")

        #expect(GestureActionCatalogue.title(of: binding) == "view.blame")
    }

    @Test func everyActionBelongsToAListedGroup() {
        for action in GestureActionCatalogue.all {
            #expect(GestureActionCatalogue.groups.contains(action.group))
        }
    }
}
