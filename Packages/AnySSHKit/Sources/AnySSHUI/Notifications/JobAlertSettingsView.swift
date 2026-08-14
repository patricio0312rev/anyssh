#if canImport(UIKit)
import AnySSHCore
import SwiftUI

public struct JobAlertSettingsView: View {
    @Bindable private var settings: JobAlertSettings

    @Environment(\.dismiss) private var dismiss
    @Environment(\.syntaxHighlighter) private var highlighter

    public init(settings: JobAlertSettings) {
        _settings = Bindable(wrappedValue: settings)
    }

    public var body: some View {
        NavigationStack {
            List {
                delivery
                shell
            }
            .catalogListSurface()
            .navigationTitle("Job alerts")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    CloseButton(accessibilityIdentifier: UIIdentifier.JobAlerts.close) { dismiss() }
                }
            }
            .accessibilityIdentifier(UIIdentifier.JobAlerts.settings)
        }
        .tint(Theme.accent)
    }

    private var delivery: some View {
        Section {
            Toggle("Quiet success alerts", isOn: $settings.suppressesSuccess)
                .font(Theme.Text.body)
                .foregroundStyle(Theme.text.primary)
                .accessibilityIdentifier(UIIdentifier.JobAlerts.quietToggle)
                .catalogRowChrome()
        } header: {
            SectionLabel("When alerts arrive")
        } footer: {
            SectionCaption(Self.deliveryCaption)
        }
    }

    private var shell: some View {
        Section {
            HighlightedCodeBlockView(
                code: ShellIntegrationSnippet.text,
                language: nil,
                highlighter: highlighter
            )
            .accessibilityIdentifier(UIIdentifier.JobAlerts.snippet)
            .catalogRowPlain()
            CopyableRow(
                label: "Copy snippet",
                value: ShellIntegrationSnippet.text,
                displaysValue: false,
                accessibilityIdentifier: UIIdentifier.JobAlerts.copySnippet
            )
            .catalogRowChrome()
        } header: {
            SectionLabel("Shell integration")
        } footer: {
            SectionCaption(Self.shellCaption)
        }
    }

    private static let deliveryCaption =
        ErrorState.notifications(.alertsSuspended).copy.body
        + " Failures always notify, even when quieted."

    private static let shellCaption =
        "Append this to the shell rc file on the host. The app shows it and never writes it for you."
}

#Preview("JobAlertSettingsView") {
    ThemedRoot {
        JobAlertSettingsView(settings: JobAlertSettings(suppressesSuccess: false))
    }
}
#endif
