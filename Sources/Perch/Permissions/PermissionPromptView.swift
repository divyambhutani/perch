import SwiftUI

struct PermissionPromptView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let session = environment.sessionStore.activeSession
        VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.permissionRequired(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.headline)

            if let request = session.pendingPermissions.first {
                content(for: request)
            } else {
                Text(PerchStrings.noPendingPermissions(tone: environment.sessionStore.currentFamiliar.tone))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func content(for request: PermissionRequest) -> some View {
        Text(request.summary)
            .font(.subheadline)
        PermissionDiffView(request: request)
        HStack {
            Button(PerchStrings.approveAction()) {
                environment.sessionStore.approvePermission(id: request.id)
            }
            .keyboardShortcut(.defaultAction)

            Button(PerchStrings.denyAction()) {
                environment.sessionStore.denyPermission(id: request.id)
            }
            .keyboardShortcut(.cancelAction)
        }
    }
}
