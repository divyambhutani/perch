import SwiftUI

struct LaunchAtLoginStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment
        let tone = environment.sessionStore.currentFamiliar.tone

        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.onboardingLaunchAtLoginTitle(tone: tone))
                .font(.title2.weight(.semibold))
            Text(PerchStrings.onboardingLaunchAtLoginBody(tone: tone))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Toggle(PerchStrings.launchAtLogin(tone: tone), isOn: $environment.launchAtLoginEnabled)
                .onChange(of: environment.launchAtLoginEnabled) { _, newValue in
                    environment.applyLaunchAtLoginChange()
                    coordinator.markLaunchAtLoginGranted(newValue && environment.launchAtLoginEnabled)
                }

            if environment.launchAtLoginRequiresApproval {
                Text(PerchStrings.launchAtLoginApprovalRequired())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button(PerchStrings.openLoginItemsSettings()) {
                    environment.openLoginItemsSettings()
                }
            }

            Spacer()

            HStack {
                Button(PerchStrings.onboardingSkip(tone: tone)) { coordinator.skip() }
                Spacer()
                Button(PerchStrings.onboardingContinue(tone: tone)) { coordinator.advance() }
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}
