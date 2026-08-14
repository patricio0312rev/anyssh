import AnySSHUI
import SwiftUI

struct AuthSavePasswordScenarioView: View {
    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                AuthSavePasswordSheet(onSave: {}, onSkip: {})
                    .presentationDetents([.height(AuthSavePasswordSheet.detentHeight)])
                    .presentationDragIndicator(.visible)
            }
    }
}
