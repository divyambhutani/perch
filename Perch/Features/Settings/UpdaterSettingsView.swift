import Sparkle
import SwiftUI

struct UpdaterSettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        return VStack(alignment: .leading, spacing: 8) {
            Text(PerchStrings.updatesTitle())
                .font(.headline)

            if environment.updaterFeedConfigured {
                Toggle(PerchStrings.automaticUpdateChecks(), isOn: $environment.automaticUpdateChecksEnabled)
                    .onChange(of: environment.automaticUpdateChecksEnabled) { _, _ in
                        environment.applyAutomaticUpdatePreference()
                    }
                Button(PerchStrings.checkForUpdatesAction(), action: checkForUpdates)
                    .disabled(!environment.canCheckForUpdates)
            } else {
                Text(PerchStrings.updaterNotConfigured())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func checkForUpdates() {
        environment.checkForUpdates()
    }
}
