import SwiftUI

struct PermissionPromptView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let session = environment.sessionStore.activeSession
        VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.permissionRequired(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.headline)

            if let request = session.pendingPermissions.first {
                Text(request.summary)
                    .font(.subheadline)
                PermissionDiffView(request: request)
                Button(PerchStrings.approveAction()) {
                    environment.sessionStore.approvePermission(id: request.id)
                }
            } else {
                Text(PerchStrings.noPendingPermissions(tone: environment.sessionStore.currentFamiliar.tone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
