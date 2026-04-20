import SwiftUI

struct LaunchAtLoginSettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        VStack(alignment: .leading, spacing: 8) {
            Toggle(PerchStrings.launchAtLogin(tone: environment.sessionStore.currentFamiliar.tone), isOn: $environment.launchAtLoginEnabled)
                .onChange(of: environment.launchAtLoginEnabled) { _, _ in
                    applyLaunchPreference()
                }

            if environment.launchAtLoginRequiresApproval {
                Text(PerchStrings.launchAtLoginApprovalRequired())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(PerchStrings.openLoginItemsSettings(), action: openLoginItemsSettings)
            }
        }
    }

    private func applyLaunchPreference() {
        environment.applyLaunchAtLoginChange()
    }

    private func openLoginItemsSettings() {
        environment.openLoginItemsSettings()
    }
}
