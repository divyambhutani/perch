import SwiftUI

struct CompleteStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        let tone = environment.sessionStore.currentFamiliar.tone

        VStack(alignment: .leading, spacing: 16) {
            Text(PerchStrings.onboardingCompleteTitle(tone: tone))
                .font(.title2.weight(.semibold))
            Text(PerchStrings.onboardingCompleteBody(tone: tone))
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()

            HStack {
                Spacer()
                Button(PerchStrings.onboardingOpenPerch(tone: tone)) {
                    coordinator.finish()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
    }
}
