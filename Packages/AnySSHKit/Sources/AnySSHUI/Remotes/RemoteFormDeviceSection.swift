import AnySSHCore
import SwiftUI

struct RemoteFormDeviceSection: View {
    @Bindable var model: RemoteFormModel

    var body: some View {
        Section {
            HStack(spacing: Theme.Space.step3) {
                RowIconTile(
                    systemImage: model.deviceType.systemImageName,
                    label: model.deviceType.label
                )
                Picker("Type", selection: $model.deviceTypeSelection) {
                    ForEach(RemoteDeviceType.allCases, id: \.self) { type in
                        Text(type.label).tag(type)
                    }
                }
                .tint(Theme.text.secondary)
                .accessibilityIdentifier(UIIdentifier.RemoteForm.deviceType)
            }
        } header: {
            SectionLabel("Device")
        } footer: {
            if let detected = model.detectedDeviceType {
                Text("Detected as \(detected.label)")
                    .font(Theme.Text.caption)
                    .foregroundStyle(Theme.text.secondary)
            }
        }
        .listRowBackground(Theme.surface.raised)
    }
}
