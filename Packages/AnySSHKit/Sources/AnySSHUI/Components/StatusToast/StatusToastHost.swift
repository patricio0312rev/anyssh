import SwiftUI

public struct StatusToastHost: View {
    @Bindable private var center: StatusToastCenter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var announcedIDs: Set<UUID> = []

    public init(center: StatusToastCenter) {
        self.center = center
    }

    public var body: some View {
        VStack(spacing: Theme.Space.step2) {
            ForEach(center.items) { toast in
                StatusToastCard(toast: toast) { center.dismiss(toast.id) }
                    .transition(cardTransition)
            }
        }
        .padding(.horizontal, Theme.Space.screenMargin)
        .padding(.bottom, Theme.Space.step3)
        .frame(maxWidth: .infinity)
        .animation(hostAnimation, value: center.items.map(\.id))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(UIIdentifier.StatusToast.host)
        .onChange(of: center.items.map(\.id)) { _, ids in
            announceNewItems(ids: ids)
        }
        .onAppear {
            announceNewItems(ids: center.items.map(\.id))
        }
    }

    private var hostAnimation: Animation? {
        reduceMotion ? nil : Theme.Motion.spring
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity)
    }

    private func announceNewItems(ids: [UUID]) {
        let fresh = center.items.filter { !announcedIDs.contains($0.id) }
        for toast in fresh {
            announcedIDs.insert(toast.id)
            AccessibilityNotification.Announcement(toast.announcement).post()
        }
        announcedIDs = announcedIDs.intersection(Set(ids))
    }
}

extension View {
    public func statusToastHost(center: StatusToastCenter) -> some View {
        statusToastCenter(center)
            .overlay(alignment: .bottom) { StatusToastHost(center: center) }
    }
}

#Preview("StatusToastHost") {
    let center = StatusToastCenter()
    return ThemedRoot(statusToasts: center) {
        Color.clear
            .task {
                center.present(severity: .success, title: "Key imported", body: "id_ed25519")
                center.present(severity: .error, title: "Connection refused", body: "port 22")
            }
    }
}
