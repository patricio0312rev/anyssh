import SwiftUI

public struct JSONTreeView: View {
    @State private var model: JSONTreeModel

    public init(model: JSONTreeModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        List(model.rows) { row in
            Button {
                model.toggle(row.id)
            } label: {
                JSONTreeRowView(row: row)
            }
            .buttonStyle(.plain)
            .catalogRowChrome()
        }
        .catalogListSurface()
        .accessibilityIdentifier(UIIdentifier.File.jsonTree)
    }
}
