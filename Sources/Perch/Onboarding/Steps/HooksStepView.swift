import SwiftUI

struct HooksStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let tone = environment.sessionStore.currentFamiliar.tone

        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.onboardingHooksTitle(tone: tone))
                .font(.title2.weight(.semibold))
            Text(PerchStrings.onboardingHooksBody(tone: tone))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if case .installed = environment.hookInstallationStatus {
                Text(PerchStrings.hooksInstalled())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack {
                Button(PerchStrings.onboardingSkip(tone: tone)) { coordinator.skip() }
                Spacer()
                Button(PerchStrings.onboardingInstallHooks(tone: tone)) {
                    environment.installHooks()
                    if case .installed = environment.hookInstallationStatus {
                        coordinator.markHooksInstalled(true)
                    }
                    coordinator.advance()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
