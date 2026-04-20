import SwiftUI

struct WelcomeStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let tone = environment.sessionStore.currentFamiliar.tone

        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.onboardingWelcomeTitle(tone: tone))
                .font(.title2.weight(.semibold))
            Text(PerchStrings.onboardingWelcomeBody(tone: tone))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Spacer()
                Button(PerchStrings.onboardingContinue(tone: tone)) {
                    coordinator.advance()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
