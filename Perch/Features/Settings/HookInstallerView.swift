import SwiftUI

struct HookInstallerView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.installHooks(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.headline)
            Text(environment.hookInstaller.installationURL().path)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(hookStatusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(PerchStrings.hookServerListening(at: environment.hookServerURL))
                .font(.caption)
                .foregroundStyle(.secondary)
            Button(PerchStrings.installHooksAction(), action: installHooks)
        }
    }

    private var hookStatusText: String {
        switch environment.hookInstallationStatus {
        case .installed:
            PerchStrings.hooksInstalled()
        case .notInstalled:
            PerchStrings.hooksNotInstalled()
        }
    }

    private func installHooks() {
        environment.installHooks()
    }
}
