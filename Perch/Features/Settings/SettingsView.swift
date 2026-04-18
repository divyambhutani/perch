import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.settingsTitle(tone: environment.sessionStore.currentFamiliar.tone))
                .font(.title3.weight(.semibold))

            ThemePickerView()
            HookInstallerView()
            LaunchAtLoginSettingsView()

            UpdaterSettingsView()

            if let lastRuntimeError = environment.lastRuntimeError {
                EmptyStateView(
                    title: PerchStrings.runtimeIssueTitle(),
                    message: lastRuntimeError
                )
            }
        }
        .padding(20)
        .frame(minWidth: 360, idealWidth: 400, maxWidth: 460, alignment: .leading)
    }
}
