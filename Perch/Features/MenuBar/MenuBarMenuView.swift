import SwiftUI

struct MenuBarMenuView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(environment.sessionStore.currentFamiliar.displayName)
                .font(.headline)

            Text(PerchStrings.overlaySubtitle(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            SessionListView()
            PermissionPromptView()
        }
        .padding(12)
        .frame(minWidth: 320, idealWidth: 360, maxWidth: 420, alignment: .leading)
    }
}
