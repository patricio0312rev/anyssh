import SwiftUI

extension View {
    public func formCardSection() -> some View {
        listRowBackground(Theme.surface.raised)
            .listRowInsets(
                EdgeInsets(
                    top: Theme.Space.step1,
                    leading: Theme.Space.cardPadding,
                    bottom: Theme.Space.step1,
                    trailing: Theme.Space.cardPadding
                )
            )
    }

    public func formSectionMargin() -> some View {
        listRowInsets(EdgeInsets())
    }
}
